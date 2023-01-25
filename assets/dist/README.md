This folder is tracked on purpose, as vite-ssg fails on compile when not finding a robots.txt,
despite `dist/` not even being the output folder (overriden through `outDir`).