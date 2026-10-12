#!/bin/bash

# ============================================================
# Odoo Project Generator
# Creates a complete Docker-based Odoo project skeleton
# with a working VS Code / VSCodium debugger setup
# (forward attach via debugpy)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║       Odoo Project Generator v1.1                    ║"
    echo "║       Docker-based development environment            ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./create-odoo-project.sh [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -n, --name <name>         Project name (required)"
    echo "  -v, --version <version>   Odoo version (default: 17.0)"
    echo "  -d, --db <dbname>         Database name (default: project name)"
    echo "  -p, --port <port>         HTTP port (default: 8069)"
    echo "  -dbport <port>            PostgreSQL port (default: 5432)"
    echo "  --pg-version <version>    PostgreSQL image version (default: auto by Odoo version)"
    echo "  --debug <ide>             Debugger support to generate:"
    echo "                              codium  (default, full setup)"
    echo "                              pycharm (TODO, placeholder only)"
    echo "                              none    (skip debugging setup)"
    echo "  -i, --interactive         Interactive mode (prompts for options)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./create-odoo-project.sh -n my-project -v 17.0"
    echo "  ./create-odoo-project.sh --name pos-app --version 16.0 --port 16000"
    echo "  ./create-odoo-project.sh -i"
    echo "  ./create-odoo-project.sh -n my-project --debug codium"
}

# Default values
PROJECT_NAME=""
ODOO_VERSION=""
DB_NAME=""
HTTP_PORT=""
DB_PORT=""
POSTGRES_VERSION=""
ADMIN_PASSWORD=""
DB_USER="odoo"
DB_PASSWORD="odoo"
PGADMIN_EMAIL="admin@example.com"
PGADMIN_PASSWORD="admin"
DEBUG_IDE="codium"
INTERACTIVE=false

# Parse arguments
ARGS_PRESENT=false
while [[ $# -gt 0 ]]; do
    ARGS_PRESENT=true
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -v|--version)
            ODOO_VERSION="$2"
            shift 2
            ;;
        -d|--db)
            DB_NAME="$2"
            shift 2
            ;;
        -p|--port)
            HTTP_PORT="$2"
            shift 2
            ;;
        --dbport)
            DB_PORT="$2"
            shift 2
            ;;
        --pg-version)
            POSTGRES_VERSION="$2"
            shift 2
            ;;
        --debug)
            DEBUG_IDE="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -h|--help)
            print_banner
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate --debug value
case "$DEBUG_IDE" in
    codium|pycharm|none) ;;
    *)
        echo -e "${RED}Error: Invalid --debug value '$DEBUG_IDE'. Use: codium, pycharm or none.${NC}"
        print_usage
        exit 1
        ;;
esac

print_banner

# If no arguments provided or -i flag, enter interactive mode
if [ "$ARGS_PRESENT" = false ] || [ "$INTERACTIVE" = true ]; then
    echo -e "${BLUE}Enter project configuration (press Enter for defaults):${NC}"
    echo ""
    
    # Project name (required)
    while true; do
        read -p "Project name (required): " PROJECT_NAME
        if [ -n "$PROJECT_NAME" ]; then
            # Validate project name (alphanumeric, hyphens, underscores)
            if [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                break
            else
                echo -e "${RED}Invalid name. Use only letters, numbers, hyphens and underscores.${NC}"
            fi
        else
            echo -e "${RED}Project name is required!${NC}"
        fi
    done
    
    # Odoo version
    while true; do
        read -p "Odoo version [17.0]: " ODOO_VERSION
        ODOO_VERSION=${ODOO_VERSION:-17.0}
        if [[ "$ODOO_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}Invalid format. Use: XX.0 (e.g., 16.0, 17.0, 18.0)${NC}"
        fi
    done
    
    # Database name
    read -p "Database name [${PROJECT_NAME}]: " DB_NAME
    DB_NAME=${DB_NAME:-$PROJECT_NAME}
    
    # HTTP port
    while true; do
        read -p "HTTP port [8069]: " HTTP_PORT
        HTTP_PORT=${HTTP_PORT:-8069}
        if [[ "$HTTP_PORT" =~ ^[0-9]+$ ]] && [ "$HTTP_PORT" -ge 1024 ] && [ "$HTTP_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}Invalid port. Use a number between 1024-65535.${NC}"
        fi
    done
    
    # PostgreSQL port
    while true; do
        read -p "PostgreSQL port [5432]: " DB_PORT
        DB_PORT=${DB_PORT:-5432}
        if [[ "$DB_PORT" =~ ^[0-9]+$ ]] && [ "$DB_PORT" -ge 1024 ] && [ "$DB_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}Invalid port. Use a number between 1024-65535.${NC}"
        fi
    done
    
    # Admin password
    read -p "Admin master password [admin]: " ADMIN_PASSWORD
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
    
    # Debugger IDE support
    echo ""
    while true; do
        read -p "Debugger support [codium|pycharm|none] (codium): " DEBUG_IDE
        DEBUG_IDE=${DEBUG_IDE:-codium}
        case "$DEBUG_IDE" in
            codium|pycharm|none) break ;;
            *) echo -e "${RED}Invalid choice. Use: codium, pycharm or none.${NC}" ;;
        esac
    done
    if [ "$DEBUG_IDE" = "pycharm" ]; then
        echo -e "${YELLOW}Note: PyCharm remote debugging is a TODO - a placeholder will be generated.${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Configuration Summary:${NC}"
    echo "  Project:       ${PROJECT_NAME}"
    echo "  Odoo Version:  ${ODOO_VERSION}"
    echo "  Database:      ${DB_NAME}"
    echo "  HTTP Port:     ${HTTP_PORT}"
    echo "  DB Port:       ${DB_PORT}"
    echo "  Debugger:      ${DEBUG_IDE}"
    echo ""
    read -p "Proceed with this configuration? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi
else
    # Validate required options for non-interactive mode
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${RED}Error: Project name is required (-n or --name)${NC}"
        print_usage
        exit 1
    fi
    
    # Set defaults for non-interactive mode
    ODOO_VERSION=${ODOO_VERSION:-17.0}
    DB_NAME=${DB_NAME:-$PROJECT_NAME}
    HTTP_PORT=${HTTP_PORT:-8069}
    DB_PORT=${DB_PORT:-5432}
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
    
    # Validate Odoo version
    if ! [[ "$ODOO_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid Odoo version format. Use format: XX.0 (e.g., 17.0)${NC}"
        exit 1
    fi
fi

# Set defaults for empty values
DB_NAME=${DB_NAME:-$PROJECT_NAME}

# Validate Odoo version
if ! [[ "$ODOO_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid Odoo version format. Use format: XX.0 (e.g., 17.0)${NC}"
    exit 1
fi

# Pick a PostgreSQL version that satisfies this Odoo major's minimum requirement
# (Odoo 19 requires 15, Odoo 20+ requires 16; older releases are fine on 13).
if [ -z "$POSTGRES_VERSION" ]; then
    case "${ODOO_VERSION%%.*}" in
        19)    POSTGRES_VERSION=15 ;;
        2[0-9]) POSTGRES_VERSION=16 ;;
        *)     POSTGRES_VERSION=13 ;;
    esac
fi

# Check if project directory already exists
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Directory '$PROJECT_NAME' already exists${NC}"
    exit 1
fi

echo -e "${GREEN}Creating Odoo ${ODOO_VERSION} project: ${PROJECT_NAME}${NC}"
echo ""

# Create directory structure
echo -e "${BLUE}[1/7] Creating directory structure...${NC}"
mkdir -p "$PROJECT_NAME"
mkdir -p "$PROJECT_NAME/config"
mkdir -p "$PROJECT_NAME/custom"
mkdir -p "$PROJECT_NAME/logs"
touch "$PROJECT_NAME/custom/.gitkeep"
touch "$PROJECT_NAME/logs/.gitkeep"

# Create Dockerfile
echo -e "${BLUE}[2/7] Creating Dockerfile...${NC}"
if [ "$DEBUG_IDE" != "none" ]; then
cat > "$PROJECT_NAME/Dockerfile" << EOF
FROM odoo:${ODOO_VERSION}

# Install debugpy for remote debugging (debug_launcher.py).
# USER root is required because the base image runs pip as the 'odoo'
# user, which would install into /var/lib/odoo/.local (hidden by the
# odoo-web volume mounted at /var/lib/odoo).
# Pin debugpy~=1.8 for VS Code / VSCodium debug adapter.
# Uses conditional install to support both Odoo 16 (no --break-system-packages)
# and Odoo 18/19+ (requires --break-system-packages for PEP 668).
USER root
RUN pip3 install --no-cache-dir "debugpy~=1.8" || pip3 install --no-cache-dir --break-system-packages "debugpy~=1.8"
USER odoo

# Install additional dependencies
# RUN pip3 install -r requirements.txt
EOF
else
cat > "$PROJECT_NAME/Dockerfile" << EOF
FROM odoo:${ODOO_VERSION}

# Install additional dependencies
# RUN pip3 install -r requirements.txt
EOF
fi

# Create docker-compose.yml
echo -e "${BLUE}[3/7] Creating docker-compose.yml...${NC}"
cat > "$PROJECT_NAME/docker-compose.yml" << EOF
services:
  odoo:
    build:
      context: .
    container_name: ${PROJECT_NAME}
    command: odoo -d ${DB_NAME} --dev=all
EOF
if [ "$DEBUG_IDE" != "none" ]; then
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
    entrypoint:
      - /debug_entrypoint.sh
EOF
fi
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
    depends_on:
      - db
    ports:
      - "${HTTP_PORT}:8069"
EOF
if [ "$DEBUG_IDE" != "none" ]; then
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
      - "\${DEBUGPY_PORT:-5678}:5678"
EOF
fi
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
    volumes:
      - odoo-web:/var/lib/odoo
      - ./config:/etc/odoo
      - ./custom:/mnt/extra-addons
      - ./logs:/var/log/odoo
EOF
if [ "$DEBUG_IDE" != "none" ]; then
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
      - ./debug_entrypoint.sh:/debug_entrypoint.sh:ro
      - ./debug_launcher.py:/mnt/debug_launcher.py:ro
EOF
fi
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
    environment:
      - PYTHONUNBUFFERED=1
EOF
if [ "$DEBUG_IDE" != "none" ]; then
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
      - DEBUGPY=\${DEBUGPY:-0}
      - DEBUGPY_PORT=\${DEBUGPY_PORT:-5678}
      - DEBUGPY_WAIT=\${DEBUGPY_WAIT:-1}
EOF
fi
cat >> "$PROJECT_NAME/docker-compose.yml" << EOF
      - HOST=db
      - PORT=5432
      - USER=${DB_USER}
      - PASSWORD=${DB_PASSWORD}
    networks:
      - odoo_net
    restart: unless-stopped

  db:
    image: postgres:${POSTGRES_VERSION}
    container_name: ${PROJECT_NAME}_db
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db:/var/lib/postgresql/data/pgdata
    networks:
      - odoo_net
    restart: unless-stopped

  pgadmin:
    image: dpage/pgadmin4
    container_name: ${PROJECT_NAME}_pgadmin
    environment:
      - PGADMIN_DEFAULT_EMAIL=${PGADMIN_EMAIL}
      - PGADMIN_DEFAULT_PASSWORD=${PGADMIN_PASSWORD}
      - PGADMIN_CONFIG_SERVER_MODE=False
    ports:
      - "5050:80"
    volumes:
      - pgadmin:/root/.pgadmin
    networks:
      - odoo_net
    depends_on:
      - db
    restart: unless-stopped

networks:
  odoo_net:

volumes:
  odoo-web:
  odoo-db:
  pgadmin:
EOF

# Create odoo.conf
echo -e "${BLUE}[4/7] Creating odoo.conf...${NC}"
cat > "$PROJECT_NAME/config/odoo.conf" << EOF
[options]
addons_path = /mnt/extra-addons
admin_passwd = ${ADMIN_PASSWORD}
data_dir = /var/lib/odoo
db_host = db
db_maxconn = 64
db_name = ${DB_NAME}
db_password = ${DB_PASSWORD}
db_port = 5432
db_sslmode = prefer
db_template = template0
db_user = ${DB_USER}
dbfilter = 
demo = {}
http_enable = True
http_interface = 
http_port = 8069
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
limit_time_real_cron = -1
list_db = True
log_db = False
log_db_level = warning
log_handler = :INFO
log_level = info
logfile = 
longpolling_port = 8072
max_cron_threads = 2
proxy_mode = False
server_wide_modules = base,web
smtp_port = 25
smtp_server = localhost
smtp_ssl = False
test_enable = False
workers = 0
EOF

# Create entrypoint.sh
echo -e "${BLUE}[5/7] Creating entrypoint.sh...${NC}"
cat > "$PROJECT_NAME/entrypoint.sh" << 'EOF'
#!/bin/bash

set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
EOF

# Create wait-for-psql.py
echo -e "${BLUE}[6/7] Creating wait-for-psql.py...${NC}"
cat > "$PROJECT_NAME/wait-for-psql.py" << 'EOF'
#!/usr/bin/env python3

import argparse
import logging
import sys
import time

import psycopg2

_logger = logging.getLogger(__name__)

if __name__ == "__main__":
    logging.basicConfig(
        format="%(asctime)s | %(levelname)s | %(message)s",
        level=logging.INFO,
    )

    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", required=True)
    parser.add_argument("--db_port", required=True)
    parser.add_argument("--db_user", required=True)
    parser.add_argument("--db_password", required=True)
    parser.add_argument("--timeout", type=int, default=5)

    args = parser.parse_args()

    timer = time.time()
    while (time.time() - timer) < args.timeout:
        try:
            conn = psycopg2.connect(
                "dbname='postgres' user='%s' host='%s' port='%s' password='%s'"
                % (args.db_user, args.db_host, args.db_port, args.db_password)
            )
            conn.close()
            _logger.info("Connected to postgresql server!")
            sys.exit(0)
        except psycopg2.OperationalError:
            _logger.info(
                "Connection to postgresql server is not yet available, retrying in %s"
                % args.timeout
            )
            time.sleep(1)

    _logger.error(
        "Could not connect to postgresql server within %s seconds" % args.timeout
    )
    sys.exit(1)
EOF

# Create debugging support files
if [ "$DEBUG_IDE" != "none" ]; then
    echo -e "${BLUE}[7/8] Creating debugging support (${DEBUG_IDE})...${NC}"

    # debug_entrypoint.sh - toggles normal vs debug mode.
    # In debug mode the 'reload' dev flag is dropped because Odoo 17
    # re-execs the process (os.execve) on python changes, which kills
    # the debugpy session. xml/qweb reload stays.
    cat > "$PROJECT_NAME/debug_entrypoint.sh" << 'EOF'
#!/bin/bash

set -e

# ============================================================
# Odoo debug entrypoint
# - Normal mode (DEBUGPY != 1): behaves like the official entrypoint
# - Debug mode  (DEBUGPY = 1): starts Odoo under debugpy (forward
#   attach). VS Code connects in to localhost:5678. The 'reload'
#   dev flag is dropped because it re-execs the process (os.execve),
#   which tears down the debugpy session; xml/qweb reload remain.
# ============================================================

if [ "${DEBUGPY:-0}" != "1" ]; then
    exec /entrypoint.sh "$@"
fi

: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

# Wait for the database to be ready
wait-for-psql.py --db_host "${HOST}" --db_port "${PORT}" \
                 --db_user "${USER}" --db_password "${PASSWORD}" --timeout=30

# Strip leading "odoo" if the command starts with it
if [ "$1" == "odoo" ]; then
    shift
fi

# Odoo 17 'reload' dev mode re-execs the process (os.execve) on python
# changes and kills the debugger. Replace --dev with xml,qweb only.
args=()
for a in "$@"; do
    case "$a" in
        --dev*)
            ;;
        *)
            args+=("$a")
            ;;
    esac
done

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

DEV_MODE="${ODOO_DEV_DEBUG:-xml,qweb}"
echo ">>> [debugpy] Launching Odoo under debugger: python3 /mnt/debug_launcher.py --dev=${DEV_MODE} ${DB_ARGS[@]} ${args[@]}"
exec python3 -u /mnt/debug_launcher.py "--dev=${DEV_MODE}" "${DB_ARGS[@]}" "${args[@]}"
EOF

    # debug_launcher.py - in-process debugpy lib + odoo starter
    # (forward attach: the container LISTENS, VS Code connects in)
    cat > "$PROJECT_NAME/debug_launcher.py" << 'EOF'
#!/usr/bin/env python3

import os
import sys

# set server timezone in UTC before time module imported
os.environ['TZ'] = 'UTC'

import debugpy

host = os.environ.get("DEBUGPY_HOST", "0.0.0.0")
port = int(os.environ.get("DEBUGPY_PORT", "5678"))
wait = os.environ.get("DEBUGPY_WAIT", "1") == "1"

# Forward attach: the container LISTENS, VS Code connects in to localhost:5678.
debugpy.listen((host, port))
print(">>> [debugpy] Odoo debugger listening on {}:{}. Start 'Attach to Odoo (Docker)' in VS Code.".format(host, port), flush=True)

if wait:
    print(">>> [debugpy] Waiting for VS Code to attach before starting Odoo (set DEBUGPY_WAIT=0 to skip)...", flush=True)
    debugpy.wait_for_client()
    print(">>> [debugpy] Debugger attached!", flush=True)

import odoo

if __name__ == "__main__":
    sys.argv[0] = "odoo"
    odoo.cli.main()
EOF

    # .env - DEBUGPY toggle for docker compose
    cat > "$PROJECT_NAME/.env" << EOF
# Odoo debug mode (forward attach)
#   Start Odoo paused for the debugger:
#     DEBUGPY=1 docker compose up -d odoo
#   then in VS Code / Codium run "Attach to Odoo (Docker)".
#   The container listens on port 5678 and VS Code connects in.
DEBUGPY=0
DEBUGPY_PORT=5678
DEBUGPY_WAIT=1

# Database
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF

    # Codium - full VS Code / VSCodium debug setup (forward attach)
    if [ "$DEBUG_IDE" = "codium" ]; then
        mkdir -p "$PROJECT_NAME/.vscode"
        cat > "$PROJECT_NAME/.vscode/launch.json" << EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Attach to Odoo (Docker)",
            "type": "debugpy",
            "request": "attach",
            "connect": {
                "host": "localhost",
                "port": 5678
            },
            "pathMappings": [
                {
                    "localRoot": "\${workspaceFolder}/custom",
                    "remoteRoot": "/mnt/extra-addons"
                },
                {
                    "localRoot": "\${workspaceFolder}/odoo-src",
                    "remoteRoot": "/usr/lib/python3/dist-packages/odoo"
                }
            ]
        }
    ]
}
EOF

        # refresh_odoo_src.sh - mirror the exact core odoo Python source
        # from the running container into ./odoo-src so VS Code can resolve
        # breakpoints in core odoo code.
        cat > "$PROJECT_NAME/refresh_odoo_src.sh" << EOF
#!/bin/bash

# Mirror the exact Odoo core Python source (only .py files) from the running
# container into ./odoo-src so VS Code can resolve breakpoints in core Odoo
# code (pathMapping: ./odoo-src -> /usr/lib/python3/dist-packages/odoo).
#
# Refresh it when you pull/rebuild a new odoo image. Requires the odoo
# container to be up (normal mode is fine).

set -euo pipefail

CONTAINER="\${1:-${PROJECT_NAME}}"
DEST="\$(dirname "\$0")/odoo-src"

docker cp "\${CONTAINER}:/usr/lib/python3/dist-packages/odoo" /tmp/odoo-src-full
rm -rf "\${DEST}"
mkdir -p "\${DEST}"
find /tmp/odoo-src-full -name '*.py' -printf '%P\n' | while read -r f; do
    mkdir -p "\${DEST}/\$(dirname "\$f")"
    cp -p "/tmp/odoo-src-full/\$f" "\${DEST}/\$f"
done
rm -rf /tmp/odoo-src-full

echo "Odoo core source mirrored to \${DEST} (\$(find "\${DEST}" -name '*.py' | wc -l) files)."
EOF
        chmod +x "$PROJECT_NAME/refresh_odoo_src.sh"
    fi

    # PyCharm - TODO placeholder (not implemented yet)
    if [ "$DEBUG_IDE" = "pycharm" ]; then
        cat > "$PROJECT_NAME/config/pycharm_debug_TODO.md" << 'EOF'
# PyCharm Remote Debugging - TODO

PyCharm remote debugging is not implemented yet.

## What is needed

1. PyCharm Professional (or Community + `python-debugger` plugin) with a
   "Python Debug Server" run configuration listening on port 5678.
2. Install `pydevd-pycharm` into the Odoo container:
   - `pip3 install pydevd-pycharm~=<pycharm_version>`
3. In `debug_launcher.py`, replace the `debugpy` block with:

   ```python
   import pydevd_pycharm
   pydevd_pycharm.settrace('localhost', port=5678, stdoutToServer=True, stderrToServer=True)
   ```

4. Expose port 5678 for the debug server (already published in docker-compose.yml).

Update this file once the setup is complete and working.
EOF
    fi

    chmod +x "$PROJECT_NAME/debug_entrypoint.sh"
fi

# Create requirements.txt
echo -e "${BLUE}[8/8] Creating requirements.txt and .gitignore...${NC}"
touch "$PROJECT_NAME/requirements.txt"

cat > "$PROJECT_NAME/.gitignore" << EOF
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
.Python

# Virtual environments
venv/
.env

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Odoo
custom/*.pyc
logs/*.log
*.log

# Docker
pgadmin/

# Odoo core source mirror (VS Code core breakpoints)
odoo-src/
EOF

# Make entrypoint executable
chmod +x "$PROJECT_NAME/entrypoint.sh"
chmod +x "$PROJECT_NAME/wait-for-psql.py"

# Create README.md
cat > "$PROJECT_NAME/README.md" << EOF
# ${PROJECT_NAME} - Odoo ${ODOO_VERSION}

## Quick Start

\`\`\`bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f odoo

# Stop all services
docker compose down
\`\`\`

## Access

- **Odoo:** http://localhost:${HTTP_PORT}
- **PgAdmin:** http://localhost:5050
  - Email: ${PGADMIN_EMAIL}
  - Password: ${PGADMIN_PASSWORD}

## Development

Custom addons are in the \`custom/\` folder. Mount them to \`/mnt/extra-addons\` in the container.

Auto-reload: normal mode runs \`odoo --dev=all\` (python + xml/qweb auto-reload).

## Services

| Service | Port | Description |
|---------|------|-------------|
| odoo | ${HTTP_PORT} | Odoo Application |
| db | ${DB_PORT} | PostgreSQL Database |
| pgadmin | 5050 | Database Management UI |
EOF

if [ "$DEBUG_IDE" = "codium" ]; then
cat >> "$PROJECT_NAME/README.md" << EOF

## Debugging (VS Code / Codium)

Debugging uses **forward attach**: the container *listens* on port \`5678\`
and VS Code connects in to \`localhost:5678\`. No reverse attach, no
\`host.docker.internal\`.

> **Why two different dev modes?** Odoo's \`reload\` dev option re-executes
> the process with \`os.execve\`, which destroys the debugpy session the
> moment a \`.py\` file changes. In debug mode the entrypoint therefore
> replaces \`--dev=all\` with \`--dev=xml,qweb\` (xml/qweb reload still work;
> python changes need a container restart: \`docker compose restart odoo\`).

### Step 1 - Start Odoo paused for the debugger

\`\`\`bash
DEBUGPY=1 docker compose up -d odoo
\`\`\`

The container waits for the VS Code debugger before starting Odoo
(\`DEBUGPY_WAIT=1\`, the default).

### Step 2 - Attach in VS Code

1. Install the **Python** extension (\`ms-python.python\`).
2. \`Ctrl+Shift+P\` → **Debug: Select and Start Debugging** →
   **"Attach to Odoo (Docker)"**.
3. Odoo boots and pauses at your breakpoints.

Set breakpoints in:
- your addons under \`custom/\` (mapped to \`/mnt/extra-addons\`), and
- **core Odoo code** via the \`odoo-src/\` mirror (mapped to
  \`/usr/lib/python3/dist-packages/odoo\`).

**Tip:** with \`DEBUGPY_WAIT=1\` the server only starts after attach, so set
startup-phase breakpoints while it's waiting, then continue.

### Restart during a debug session

After changing Python code: \`docker compose restart odoo\` (it re-enters the
paused-wait state; attach again).

### Stop debugging / return to normal

\`\`\`bash
docker compose up -d odoo   # DEBUGPY defaults to 0 (normal mode)
\`\`\`

## Debug options (\`.env\`)

| Variable | Default | Meaning |
|----------|---------|---------|
| \`DEBUGPY\` | \`0\` | \`1\` = run Odoo under the debugger |
| \`DEBUGPY_PORT\` | \`5678\` | Port the container listens on |
| \`DEBUGPY_WAIT\` | \`1\` | \`1\` = pause at startup until attached; \`0\` = start immediately, pause only at breakpoints |

## Refreshing the core source mirror

\`odoo-src/\` is a read-only mirror (only \`.py\` files) copied verbatim from
the running image so core breakpoints hit the exact same lines. Refresh after
pulling/rebuilding a new \`odoo:${ODOO_VERSION}\` image:

\`\`\`bash
./refresh_odoo_src.sh
\`\`\`

| Service | Port | Description |
|---------|------|-------------|
| odoo (debug) | 5678 | debugpy listener - attach from VS Code |
EOF
fi

if [ "$DEBUG_IDE" = "pycharm" ]; then
cat >> "$PROJECT_NAME/README.md" << EOF

## Debugging (PyCharm) - TODO

PyCharm remote debugging is **not implemented yet**.
See \`config/pycharm_debug_TODO.md\` for what is required.
EOF
fi

cat >> "$PROJECT_NAME/README.md" << EOF

## Environment Variables

- DB_USER: ${DB_USER}
- DB_PASSWORD: ${DB_PASSWORD}
- DB_NAME: ${DB_NAME}
EOF

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Project '${PROJECT_NAME}' created successfully!       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  cd ${PROJECT_NAME}"
echo "  docker compose up -d"
echo ""
echo -e "${YELLOW}Access:${NC}"
echo "  Odoo:    http://localhost:${HTTP_PORT}"
echo "  PgAdmin: http://localhost:5050"
if [ "$DEBUG_IDE" = "codium" ]; then
    echo ""
    echo -e "${YELLOW}Debugging (Codium):${NC}"
    echo "  DEBUGPY=1 docker compose up -d odoo"
    echo "  Then Attach to Odoo (Docker) in VS Code / Codium"
fi
if [ "$DEBUG_IDE" = "pycharm" ]; then
    echo ""
    echo -e "${YELLOW}Debugging (PyCharm):${NC} TODO - see config/pycharm_debug_TODO.md"
fi
echo ""