# AGENTS.md

Baidu Pan (百度网盘) share-transfer CLI. It recursively copies a shared folder into your account, splitting batches when Baidu's free-tier per-transfer file cap (errno 12) is hit.

## Commands

- Install deps: `python3 -m pip install -r requirements.txt` (only `aiohttp`, `pyyaml`)
- Run from repo root: `python3 -m baidutransfer <share-url> [-r /remote/path] [-p pwd] [-C cookie | -c config.yaml]`
- Dependency-free syntax check: `python3 -m compileall -q baidutransfer`
- Build single-file binary: `pyinstaller --name baidutransfer --onefile baidutransfer/__main__.py`
  (the committed `baidutransfer.spec` is Windows-oriented and uses backslash paths)
- Windows build: run `build.bat`; it deletes/recreates `.venv`, installs deps, and writes `dist\baidutransfer.exe`. Keep the file CRLF-encoded.
- Linux build: run `./build.sh`; same delete/recreate venv flow, writes `dist/baidutransfer`.

There are no tests, lint, format, typecheck, or CI configs. Do not invent them; the only real verification is a live run against a valid cookie and share URL. `VERSION` is read from `baidutransfer/__init__.py` by `setup.py`.

## Layout and flow

- `baidutransfer/__main__.py` — argparse, config loading, logging setup.
- `baidutransfer/transfer.py` — `BaiduFileTransfer`: `init_share_data()` → recursive enumeration → `transfer_dirs()` halves the directory list and recurses whenever a transfer-limit error occurs.
- `baidutransfer/apis.py` — raw Baidu endpoints; `baidutransfer/utils.py` — aiohttp wrapper, logger, and exception types.

## Gotchas

- Imports are absolute (`from baidutransfer import ...`). Run as a module from the repo root; `python baidutransfer/__main__.py` fails.
- Cookie precedence: `-C` beats `config.yaml`; the default `config.yaml` is looked up in the CWD and a missing file is silently ignored, so a "cookie missing" error usually means wrong CWD.
- `apis.get_share_data()` scrapes the `locals.mset(...)` blob out of the share HTML page. A Baidu frontend change breaks this, not local logic.
- `bdstoken` raises if unset; `get_share_data()` sets it. Password-protected links must call `update_randsk()` first.
- `utils.http_request()` reads only the lowercase `https_proxy` env var and disables TLS verification.
- `transfer.py` batches file transfers at 500 (`/share/transfer` rejects >500 in one call and reports the limit in errno 12); keep the batch size at 500, and note that `transfer_files()` creates its destination directory first.
- `/share/list` silently caps responses at 100 entries even when `num=1000`, so `apis.list_share_dir()` paginates until a page comes back short. Any new listing code must do the same or it will silently drop files.
- `config.yaml`, `新建文件夹/`, `新建文本文档.txt`, `build/`, `dist/`, and `*.spec` are gitignored. `config.yaml` and the copies under `新建文件夹/` hold live Baidu session cookies — never commit them or paste their values into code, docs, or logs.
- Prebuilt binaries and a Windows config live under `dist/` and `新建文件夹/`; they are artifacts, not sources.
