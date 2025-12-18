# Docker Database Setup for Mini Mart POS

This Flutter app automatically integrates with PostgreSQL using Docker for seamless database management across all platforms (Windows, macOS, Linux).

## Quick Start

### 1. Install Docker
- **Windows**: Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
- **macOS**: Download and install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
- **Linux**: Install Docker Engine following the [official Linux installation guide](https://docs.docker.com/engine/install/)

### 2. Start Docker
- **Windows/macOS**: Launch Docker Desktop application
- **Linux**: Start Docker service:
  ```bash
  sudo systemctl start docker
  sudo systemctl enable docker  # Optional: Start on boot
  ```

### 3. Install Docker Compose (Linux only)
- **Windows/macOS**: Docker Compose is included with Docker Desktop
- **Linux**: Install Docker Compose:
  ```bash
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  ```

### 4. Run the App
```bash
flutter run
```

The app will automatically:
1. Check if Docker is available
2. Start PostgreSQL container if needed
3. Initialize database with tables and sample data
4. Connect to the database
5. Show the login screen when ready

## How It Works

### Automatic Database Initialization
- The app includes a `DockerService` that manages PostgreSQL container lifecycle
- Docker configuration is defined in `docker-compose.yml`
- Database initialization happens on app startup with a user-friendly loading screen

### Graceful Fallback
- If Docker is not available, the app continues to run
- Database features will be disabled, but you can still see the UI
- No app crashes - always a smooth user experience

### Database Configuration
- **Database Name**: `pos_db`
- **Username**: `postgres`
- **Password**: `password`
- **Port**: `5432`
- **Container Name**: `mini_mart_pos_db`

## Manual Docker Commands

### Start PostgreSQL Container Manually
```bash
docker-compose up -d postgres
```

### Stop PostgreSQL Container
```bash
docker-compose down
```

### View Container Logs
```bash
docker-compose logs postgres
```

### Connect to Database Directly
```bash
docker exec -it mini_mart_pos_db psql -U postgres -d pos_db
```

## Database Schema

The database automatically creates these tables:
- `roles` - User roles (Admin, Cashier, Manager)
- `users` - System users with authentication
- `categories` - Product categories
- `suppliers` - Product suppliers
- `products` - Inventory items with barcode support
- `customers` - Customer information
- `sales` - Sales transactions
- `sale_items` - Individual sale line items
- `stock_movements` - Inventory tracking
- `purchases` - Purchase orders
- `purchase_items` - Purchase line items
- `expense_categories` - Expense categorization
- `expenses` - Business expense tracking

## Default Data

The system automatically creates:
- **Default Roles**: Admin, Cashier, Manager
- **Default Users**:
  - `admin` (password: admin123)
  - `cashier` (password: cashier123)
- **Sample Categories**: Beverages, Snacks, Home & Living, Personal Care, Electronics
- **Sample Products**: Coca Cola, Lay's Chips, Bottled Water

## Troubleshooting

### Docker Permission Issues (macOS/Linux)
If you get permission denied errors:
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect

# macOS: Make sure Docker Desktop is running with proper permissions
```

### Docker Not Running
Start Docker service:
- **macOS/Windows**: Open Docker Desktop application
- **Linux**: `sudo systemctl start docker`

### Port Conflicts
If port 5432 is already in use, modify the port in `docker-compose.yml`:
```yaml
ports:
  - "5433:5432"  # Use port 5433 instead
```

### Reset Database
To completely reset the database:
```bash
docker-compose down -v  # Remove volumes
docker-compose up -d postgres  # Start fresh
```

## Development Notes

- The app uses `process_run` package for cross-platform shell command execution
- Database initialization is asynchronous with loading indicators
- Error handling ensures the app never crashes due to database issues
- Container management is automatic - no manual Docker knowledge required

## Production Deployment

For production deployment:
1. Update database passwords in `docker-compose.yml`
2. Use environment variables for sensitive configuration
3. Consider using Docker volumes for persistent data storage
4. Implement proper backup strategies for the database

---

**Note**: This Docker integration makes the Mini Mart POS truly portable - it will work the same way on Windows, macOS, and Linux without any manual database setup!