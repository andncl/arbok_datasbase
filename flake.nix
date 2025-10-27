{
  description = "Local PostgreSQL measurement database with MinIO object storage for experimental data.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        postgres = pkgs.postgresql_15;
        minio = pkgs.minio;
        mc = pkgs.minio-client;

	postgresConf = ./config/postgresql.conf;
	pgHbaConf    = ./config/pg_hba.conf;
      in {
        devShells.default = pkgs.mkShell {
          name = "pg-minio-dev-shell";

          packages = [
            postgres
            minio
            mc
          ];

          shellHook = ''
            # --- Define base dev paths ---
            export DEV_ROOT="$PWD/data"
            export PGDATA="$DEV_ROOT/pgdata"
            export PGSOCKET="$DEV_ROOT/pgsock"
            export MINIO_DATA_DIR="$DEV_ROOT/minio"

            mkdir -p "$PGDATA" "$PGSOCKET" "$MINIO_DATA_DIR"

            echo "📂 Using development paths:"
            echo "   🗄   PGDATA         = $PGDATA"
            echo "   🧵  PGSOCKET       = $PGSOCKET"
            echo "   🪣  MINIO_DATA_DIR = $MINIO_DATA_DIR"
            echo

            # --- Initialize PostgreSQL data directory if needed ---
            if [ ! -f "$PGDATA/PG_VERSION" ]; then
              echo "⚙️  Initializing PostgreSQL data directory..."
              initdb -D "$PGDATA"

              echo "🧩 Writing PostgreSQL configuration..."
              echo "📄 Copying external PostgreSQL configuration..."
              cp ${postgresConf} "$PGDATA/postgresql.conf"

              # Patch unix_socket_directories dynamically
              sed -i "s|unix_socket_directories *=.*|unix_socket_directories = '$PGSOCKET'|" "$PGDATA/postgresql.conf"

              echo "🧩 Copying external pg_hba.conf..."
              cp ${pgHbaConf} "$PGDATA/pg_hba.conf"
            fi

            echo "✅ PostgreSQL data directory is ready at $PGDATA"
            echo "   ▶️To start PostgreSQL, run:"
            echo "     pg_ctl -D \"\$PGDATA\" -o \"-k \$PGSOCKET\" -l logfile start"
            echo
            echo "   ⏹  To stop:"
            echo "     pg_ctl -D \"\$PGDATA\" -o \"-k \$PGSOCKET\" stop"
            echo
            echo "   ℹ️ Check status:"
            echo "     pg_ctl -D \"\$PGDATA\" -o \"-k \$PGSOCKET\" status"
            echo

            echo "   🔗 Connect with SQLAlchemy:"
            echo "      postgresql+psycopg2://localhost:5432/postgres"
	    echo

            # --- Setup MinIO ---
            export MINIO_ROOT_USER=minioadmin
            export MINIO_ROOT_PASSWORD=minioadmin

            # Start MinIO if not already running
            if ! pgrep -f "minio server $MINIO_DATA_DIR$" >/dev/null; then
              echo "🪣 Starting MinIO server on http://localhost:9000 ..."
	      (
	        cd "$DEV_ROOT"
                minio server "$MINIO_DATA_DIR" \
                  --address :9000 \
                  --console-address :9001 \
                  > "minio.log" 2>&1 &
	      )
              sleep 2
	    else
	      echo "ℹ️  MinIO already running, skipping start."
            fi
            alias stopminio='
            if [ -f "$DEV_ROOT/minio.pid" ]; then
                kill $(cat "$DEV_ROOT/minio.pid") && echo "🛑 MinIO stopped"
                rm "$DEV_ROOT/minio.pid"
            else
                echo "ℹ️  No MinIO PID file found; maybe it is not running."
            fi
            '
            # Configure default bucket
            mc alias set localminio http://localhost:9000 minioadmin minioadmin >/dev/null 2>&1
            mc ls localminio/dev >/dev/null 2>&1 || mc mb localminio/dev >/dev/null 2>&1

            echo "✅ MinIO web UI: http://localhost:9001"
            echo "   S3 Endpoint:  http://localhost:9000"
            echo "   Access Key:   minioadmin"
            echo "   Secret Key:   minioadmin"
            echo "   To stop mini0 server, run: stopminio" 
          '';
        };
      });
}

