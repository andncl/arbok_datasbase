# 🧪 PostgreSQL + MinIO Measurement Database (Nix Flake)

A reproducible development environment providing a **PostgreSQL measurement database** with **MinIO object storage**, designed for local experiments and data-driven workflows.

---

## Overview

This flake sets up:

- 🐘 **PostgreSQL 15** — local database instance for structured measurement data  
- 🪣 **MinIO** — lightweight, S3-compatible object storage  
- 🧩 Automatic initialization of `postgresql.conf` and `pg_hba.conf` from external files  
- 💾 Persistent local data directories under `./data/`

---

## 🧱 Directory Structure
```
arbok_database/
├── flake.nix
├── config/
│   ├── postgresql.conf       # Custom PostgreSQL configuration template
│   └── pg_hba.conf           # Host-based authentication config
├── data/                     # Created automatically by shellHook
│   ├── pgdata/               # PostgreSQL data directory (after initdb)
│   ├── pgsock/               # UNIX socket directory for PostgreSQL
│   └── minio/                # MinIO data storage root
└── minio.log                 # Runtime log written when MinIO starts
```


---

## ⚙️ Getting Started

### 1️⃣ Enter the dev shell

```bash
nix develop

### Start/Stop PostgreSQL
pg_ctl -D "$PGDATA" -o "-k $PGSOCKET" -l logfile start
pg_ctl -D "$PGDATA" -o "-k $PGSOCKET" stopi
```

### Start/Stop MinIO
MinIO starts automatically when entering the shell.
You can stop it manually using:
```bash
stopminio
```

### Connect via SQLAlchemy

Example pythin connection using TCP:

```python
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://localhost:5432/postgres")
```

or via Unix socket:
```python
socket_dir = "/path/to/data/pgsock"
engine = create_engine(f"postgresql+psycopg2:///postgres?host={socket_dir}")
```

## Tips
- Data is stored under `./data`, so you can safely rebuild or re-enter the flake shell withoutloosing data
- Logs are written to `data/mini.log`
- The configuration files (`postgresql.conf and `pg_hba.conf`) can be customized outside the flake and are imported and configured automatically
