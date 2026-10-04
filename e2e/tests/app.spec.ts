import { type Browser, type Page, expect, test } from '@playwright/test'

// One end-to-end walk through the app with two people (separate browser contexts,
// so separate localStorage): create a room, invite, manage games, vote, log a
// session, check history/statistics, then kick and leave.

const suffix = Date.now().toString(36)
const roomName = `E2E room ${suffix}`

type Person = { page: Page, errors: string[] }

// Any uncaught error or failed API call fails the test, even if the UI looks fine
async function person(browser: Browser): Promise<Person> {
  const context = await browser.newContext()
  const page = await context.newPage()
  const errors: string[] = []
  page.on('pageerror', error => errors.push(`pageerror: ${error.message}`))
  page.on('console', message => message.type() === 'error' && errors.push(`console: ${message.text()}`))
  page.on('console', message => message.type() === 'warning' && console.log(`WARN: ${message.text().slice(0, 300)}`))
  page.on('requestfailed', request => request.url().includes('/api/') && errors.push(`requestfailed: ${request.method()} ${request.url()} ${request.failure()?.errorText}`))
  page.on('response', response => response.url().includes('/api/') && response.status() >= 400 && errors.push(`http ${response.status()}: ${response.request().method()} ${response.url()}`))
  return { page, errors }
}

function gameCard(page: Page, name: string) {
  return page.locator('#games > li').filter({ has: page.getByText(name, { exact: true }) })
}

// The UI updates optimistically and fires API calls without awaiting them, so wait
// for the response before reloading (a reload would abort the request)
async function afterApi(page: Page, method: string, path: string, action: () => Promise<void>) {
  const response = page.waitForResponse(r => r.request().method() === method && new URL(r.url()).pathname.startsWith(`/api/${path}`))
  await action()
  await response
}

async function votes(page: Page, game: string) {
  const counts = gameCard(page, game).locator('.flex.mt-2 > span')
  return { up: counts.nth(0), down: counts.nth(1) }
}

test.describe.configure({ mode: 'serial' })

test('full flow', async ({ browser }) => {
  const alice = await person(browser)
  const bob = await person(browser)

  // --- Alice creates a room and lands on its settings page
  await alice.page.goto('/')
  await expect(alice.page.getByText('You have no rooms yet')).toBeVisible()
  await alice.page.getByLabel('Room name').fill(roomName)
  await alice.page.getByLabel('Your name').fill('Alice')
  await alice.page.getByRole('button', { name: 'Save' }).click()
  await expect(alice.page).toHaveURL(/\/room\/[0-9a-f-]+\/settings$/)
  const roomPath = new URL(alice.page.url()).pathname.replace(/\/settings$/, '')

  const inviteUrl = await alice.page.locator('input[readonly]').inputValue()
  expect(inviteUrl).toMatch(/\/join\/[0-9a-f-]+$/)

  // --- Bob opens the invite, sees Alice, and joins as a new member
  await bob.page.goto(new URL(inviteUrl).pathname)
  await expect(bob.page.getByText(roomName)).toBeVisible()
  await expect(bob.page.getByRole('button', { name: 'Join as Alice' })).toBeVisible()
  await bob.page.getByLabel('Your name').fill('Bob')
  await bob.page.getByRole('button', { name: 'Save' }).click()
  await expect(bob.page).toHaveURL(new RegExp(`${roomPath}/poll$`))

  // Visiting the invite again as a member redirects to the room
  await bob.page.goto(new URL(inviteUrl).pathname)
  await expect(bob.page).toHaveURL(new RegExp(`${roomPath}/poll$`))

  // --- Alice manages games: add two, edit one, delete one
  await alice.page.goto(`${roomPath}/games`)
  await expect(alice.page.getByText('You haven\'t defined any games yet')).toBeVisible()
  const owners = alice.page.getByRole('group', { name: 'Game owners' })
  await expect(owners.getByLabel('Bob')).toBeVisible() // room members were refreshed from the API

  await alice.page.getByLabel('Name', { exact: true }).fill('Catan')
  await alice.page.locator('#form select').selectOption('4')
  await owners.getByLabel('Alice').check()
  await alice.page.getByRole('button', { name: 'Save' }).click()
  await expect(alice.page.getByRole('button', { name: 'Edit Catan' })).toBeVisible()

  await alice.page.getByLabel('Name', { exact: true }).fill('Azul')
  await alice.page.getByRole('button', { name: 'Save' }).click()
  await expect(alice.page.getByRole('button', { name: 'Edit Azul' })).toBeVisible()

  await alice.page.getByRole('button', { name: 'Edit Catan' }).click()
  await expect(alice.page.getByLabel('Name', { exact: true })).toHaveValue('Catan')
  await expect(owners.getByLabel('Alice')).toBeChecked()
  await alice.page.getByLabel('Name', { exact: true }).fill('Catan Deluxe')
  await afterApi(alice.page, 'PATCH', 'games', () => alice.page.getByRole('button', { name: 'Save' }).click())
  await expect(alice.page.getByRole('button', { name: 'Edit Catan Deluxe' })).toBeVisible()

  await alice.page.getByRole('button', { name: 'Delete Azul' }).click()
  await afterApi(alice.page, 'DELETE', 'games', () => alice.page.getByRole('button', { name: 'Confirm?' }).click())
  await expect(alice.page.getByRole('button', { name: 'Edit Azul' })).toHaveCount(0)

  // Changes survive a reload (i.e. they reached the API)
  await alice.page.reload()
  await expect(alice.page.getByRole('button', { name: 'Edit Catan Deluxe' })).toBeVisible()
  await expect(alice.page.getByRole('button', { name: 'Edit Azul' })).toHaveCount(0)
  await alice.page.getByRole('button', { name: 'Edit Catan Deluxe' }).click()
  await expect(owners.getByLabel('Alice')).toBeChecked()
  await expect(alice.page.locator('#form select')).toHaveValue('4')

  // --- Voting: Alice up, Bob down, both see both votes
  await alice.page.goto(`${roomPath}/poll`)
  await expect(gameCard(alice.page, 'Catan Deluxe')).toBeVisible()
  await gameCard(alice.page, 'Catan Deluxe').getByRole('button', { name: 'Vote up' }).click()
  await expect((await votes(alice.page, 'Catan Deluxe')).up).toHaveText('1')

  await bob.page.goto(`${roomPath}/poll`)
  await expect((await votes(bob.page, 'Catan Deluxe')).up).toHaveText('1')
  await gameCard(bob.page, 'Catan Deluxe').getByRole('button', { name: 'Vote down' }).click()
  await expect((await votes(bob.page, 'Catan Deluxe')).down).toHaveText('1')

  await alice.page.getByRole('button', { name: 'Refresh votes' }).click()
  await expect((await votes(alice.page, 'Catan Deluxe')).down).toHaveText('1')

  // Changing and removing a vote
  await afterApi(alice.page, 'PATCH', 'votes', () => gameCard(alice.page, 'Catan Deluxe').getByRole('button', { name: 'Vote down' }).click())
  await expect((await votes(alice.page, 'Catan Deluxe')).up).toHaveText('0')
  await expect((await votes(alice.page, 'Catan Deluxe')).down).toHaveText('2')
  await afterApi(alice.page, 'DELETE', 'votes', () => gameCard(alice.page, 'Catan Deluxe').getByRole('button', { name: 'Vote down' }).click())
  await expect((await votes(alice.page, 'Catan Deluxe')).down).toHaveText('1')
  await alice.page.reload()
  await expect((await votes(alice.page, 'Catan Deluxe')).up).toHaveText('0')
  await expect((await votes(alice.page, 'Catan Deluxe')).down).toHaveText('1')

  // --- Alice logs a session that she won
  await gameCard(alice.page, 'Catan Deluxe').getByText('Catan Deluxe', { exact: true }).click()
  await gameCard(alice.page, 'Catan Deluxe').getByRole('button', { name: 'Log session' }).click()
  const sessionForm = alice.page.getByRole('form', { name: 'Log session of Catan Deluxe' })
  await sessionForm.getByLabel('Alice').check()
  await sessionForm.getByLabel('Comments').fill('close game')
  await sessionForm.getByRole('button', { name: 'Save' }).click()
  await expect(alice.page.getByText('Logged successfully')).toBeVisible()

  // --- History shows it, for both
  for (const { page } of [alice, bob]) {
    await page.goto(`${roomPath}/history`)
    const entry = page.locator('ul > li').filter({ hasText: 'Catan Deluxe' })
    await expect(entry).toHaveCount(1)
    await expect(entry).toContainText('close game')
    await expect(entry.locator('dt').nth(2)).toHaveText('Alice') // winners
    await expect(entry.locator('dt').nth(3)).toHaveText('Alice, Bob') // players
  }

  // --- Statistics render charts
  await alice.page.goto(`${roomPath}/statistics`)
  await expect(alice.page.locator('canvas').first()).toBeVisible()

  // --- Members with logged sessions can't be kicked, but can be left out of the poll
  await alice.page.goto(`${roomPath}/settings`)
  const bobSettings = alice.page.locator('li').filter({ hasText: 'Bob' })
  await expect(bobSettings.getByRole('button', { name: 'Kick' })).toBeDisabled()
  await afterApi(alice.page, 'PATCH', 'members', () => bobSettings.getByLabel('Active', { exact: true }).uncheck())
  await alice.page.goto(`${roomPath}/poll`)
  await expect(alice.page.locator('#presence').getByText('Alice')).toBeVisible()
  await expect(alice.page.locator('#presence').getByText('Bob')).toHaveCount(0)

  // --- History entries can be deleted
  await bob.page.goto(`${roomPath}/history`)
  await bob.page.getByRole('button', { name: 'Delete' }).click()
  await afterApi(bob.page, 'DELETE', 'sessions', () => bob.page.getByRole('button', { name: 'Confirm?' }).click())
  await expect(bob.page.getByText('No games have been logged yet.')).toBeVisible()
  await bob.page.reload()
  await expect(bob.page.getByText('No games have been logged yet.')).toBeVisible()

  // --- Settings: rename, kick, leave
  await alice.page.goto(`${roomPath}/settings`)
  const ownName = alice.page.locator('li input:not([readonly]):not([type="checkbox"])')
  await ownName.fill('Alicia')
  await afterApi(alice.page, 'PATCH', 'members', () => alice.page.getByRole('button', { name: 'Change name' }).click())
  await alice.page.reload()
  await expect(ownName).toHaveValue('Alicia')

  const bobRow = alice.page.locator('li').filter({ hasText: 'Bob' })
  await bobRow.getByRole('button', { name: 'Kick' }).click()
  await bobRow.getByRole('button', { name: 'Click again to confirm' }).click()
  await expect(alice.page.locator('li').filter({ hasText: 'Bob' })).toHaveCount(0)
  await alice.page.reload()
  await expect(alice.page.getByText('Bob', { exact: true })).toHaveCount(0)

  await alice.page.getByRole('button', { name: 'Leave room' }).click()
  await alice.page.getByRole('button', { name: 'Click again to confirm' }).click()
  await expect(alice.page).toHaveURL(/\/$/)
  await expect(alice.page.getByText('You have no rooms yet')).toBeVisible()

  // --- Translations are loaded: cycling through every language changes the UI text
  const languageButton = alice.page.locator('footer button').filter({ hasText: /\[[a-z]{2}\]/ })
  const formTitle = alice.page.locator('form h2')
  const formTitles = [await formTitle.innerText()]
  for (let i = 0; i < 2; i++) {
    await languageButton.click()
    await expect(formTitle).not.toHaveText(formTitles.at(-1)!)
    formTitles.push(await formTitle.innerText())
  }
  expect(formTitles.sort()).toEqual(['Crear grup', 'Crear grupo', 'Create room'])

  expect(alice.errors, 'errors in Alice\'s browser').toEqual([])
  expect(bob.errors, 'errors in Bob\'s browser').toEqual([])
})

// Holds the next request matching `method` and `path` until `release()` is called
async function holdNextRequest(page: Page, method: string, path: string) {
  let release!: () => void
  const released = new Promise<void>(resolve => release = resolve)
  let held = false
  await page.route(url => url.pathname === `/api/${path}`, async (route) => {
    if (route.request().method() !== method || held) {
      return route.fallback()
    }
    held = true
    await released
    await route.continue()
  })
  return { release }
}

// A refresh answered before a vote was saved used to drop the vote from the screen, so clicking
// it again created a duplicate. Voting and refreshing must not overlap
test('voting and refreshing votes never overlap', async ({ browser }) => {
  const carol = await person(browser)
  const page = carol.page

  await page.goto('/')
  await page.getByLabel('Room name').fill(`${roomName} (refresh race)`)
  await page.getByLabel('Your name').fill('Carol')
  await page.getByRole('button', { name: 'Save' }).click()
  await expect(page).toHaveURL(/\/room\/[0-9a-f-]+\/settings$/)
  const roomPath = new URL(page.url()).pathname.replace(/\/settings$/, '')

  await page.goto(`${roomPath}/games`)
  await page.getByLabel('Name', { exact: true }).fill('Azul')
  // the poll hides games nobody owns
  await page.getByRole('group', { name: 'Game owners' }).getByLabel('Carol').check()
  await page.getByRole('button', { name: 'Save' }).click()
  await expect(page.getByRole('button', { name: 'Edit Azul' })).toBeVisible()

  await page.goto(`${roomPath}/poll`)
  const refreshButton = page.getByRole('button', { name: 'Refresh votes' })
  const voteUpButton = gameCard(page, 'Azul').getByRole('button', { name: 'Vote up' })
  await expect(voteUpButton).toBeEnabled()

  // no voting while a refresh is in flight
  const refresh = await holdNextRequest(page, 'GET', 'votes')
  await refreshButton.click()
  await expect(voteUpButton).toBeDisabled()
  refresh.release()
  await expect(voteUpButton).toBeEnabled()

  // no refreshing while a vote is being saved
  const voteRequest = await holdNextRequest(page, 'POST', 'votes')
  await voteUpButton.click()
  await expect(refreshButton).toBeDisabled()
  await expect(voteUpButton).toBeDisabled()
  await afterApi(page, 'POST', 'votes', async () => voteRequest.release())
  await expect(refreshButton).toBeEnabled()
  await expect((await votes(page, 'Azul')).up).toHaveText('1')

  // and the API has exactly that one vote
  await page.unrouteAll()
  await page.reload()
  await expect((await votes(page, 'Azul')).up).toHaveText('1')

  expect(carol.errors, 'errors in Carol\'s browser').toEqual([])
})
