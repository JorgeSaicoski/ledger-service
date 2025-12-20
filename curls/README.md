# Ledger Service API - cURL Collections

This directory contains organized API request collections for the Ledger Service in two formats:
- **JetBrains** (IntelliJ IDEA / GoLand HTTP Client format)
- **Postman** (Postman Collection format)

## Directory Structure

```
curls/
├── jetbrains/
│   ├── http-client.env.json          # Environment variables
│   └── ledger-api.http                # HTTP requests file
├── postman/
│   ├── ledger-service-api.postman_collection.json      # Postman collection
│   └── ledger-service-local.postman_environment.json   # Postman environment
└── README.md                           # This file
```

## API Endpoints Overview

The Ledger Service provides the following endpoints:

### Transactions
- `POST /transactions` - Create a new transaction
- `GET /transactions/{id}` - Get a transaction by ID
- `GET /transactions?user_id={id}` - List transactions for a user
- `GET /transactions?user_id={id}&currency={currency}` - List transactions filtered by user and currency

### Balance
- `GET /balance?user_id={id}` - Get balance across all currencies for a user
- `GET /balance?user_id={id}&currency={currency}` - Get balance for a specific currency

---

## JetBrains HTTP Client (IntelliJ IDEA / GoLand)

### Getting Started

1. **Open the HTTP file**
   - Navigate to `curls/jetbrains/ledger-api.http`
   - The file will open in the HTTP Client editor

2. **Select Environment**
   - Click on the environment selector (top right)
   - Choose `dev` or `local` environment
   - Environments are defined in `http-client.env.json`

3. **Run Requests**
   - Click the green play button (▶) next to any request
   - Or use keyboard shortcut: `Ctrl+Enter` (Linux/Windows) or `Cmd+Return` (Mac)
   - Results appear in the "Run" tool window

### Features

- **Environment Variables**: Defined in `http-client.env.json`
  - `baseUrl`: Service endpoint (default: `http://localhost:8080`)

- **Response Handlers**: Automatic test assertions using JavaScript
  - Tests run automatically after each request
  - Results shown in the response panel

- **Variable Capture**: The `transaction_id` is automatically captured from create requests
  - Used in subsequent "Get Transaction by ID" requests

### Request Separators

Requests are separated by `###` markers. Each section is a complete HTTP request.

### Example Usage

1. Run "Create Transaction - Positive Amount (USD)" - this captures the transaction ID
2. Run "Get Transaction by ID" - this uses the captured ID
3. Run "List Transactions by User ID" - see all transactions for that user
4. Run "Get Balance for User" - see the calculated balance

---

## Postman

### Getting Started

1. **Import the Collection**
   - Open Postman
   - Click "Import" button
   - Select `curls/postman/ledger-service-api.postman_collection.json`
   - Click "Import"

2. **Import the Environment**
   - Click "Import" again
   - Select `curls/postman/ledger-service-local.postman_environment.json`
   - Click "Import"

3. **Select Environment**
   - In the top-right corner, select "Ledger Service - Local" from the environment dropdown

4. **Run Requests**
   - Expand the collection in the left sidebar
   - Click on any request to view it
   - Click "Send" button to execute

### Features

- **Organized Folders**:
  - `Transactions` - All transaction-related endpoints
  - `Balance` - Balance calculation endpoints
  - `Validation Tests` - Error and validation test cases

- **Pre-configured Tests**: Each request includes test scripts
  - Automatically validate response status codes
  - Verify response structure
  - Capture variables for subsequent requests

- **Environment Variables**:
  - `baseUrl` - Service endpoint
  - `transaction_id` - Auto-captured from create requests

### Running Collection

You can run the entire collection or specific folders:

1. **Run Full Collection**:
   - Click the three dots (⋯) next to the collection name
   - Select "Run collection"
   - Configure iterations and environment
   - Click "Run Ledger Service API"

2. **Run Specific Folder**:
   - Click the three dots next to a folder (e.g., "Transactions")
   - Select "Run folder"

3. **View Results**:
   - Test results appear in the "Test Results" tab
   - See which tests passed/failed

### Example Workflow

1. Create a transaction → `transaction_id` is captured
2. Get transaction by ID → Uses captured `transaction_id`
3. List transactions → See all transactions
4. Get balance → See calculated balance
5. Run validation tests → Verify error handling

---

## Test Coverage

Both collections include comprehensive test coverage:

### Happy Path Tests
- ✅ Create transaction with positive amount (USD)
- ✅ Create transaction with negative amount (withdrawal)
- ✅ Create transaction in different currencies (BRL, EUR)
- ✅ Create transaction with custom currency (loyalty_points)
- ✅ Get transaction by ID
- ✅ List all transactions
- ✅ List transactions filtered by user_id
- ✅ List transactions filtered by user_id and currency
- ✅ Get balance for user (all currencies)
- ✅ Get balance for user (specific currency)

### Validation Tests
- ❌ Empty user_id (should return 400)
- ❌ Invalid user_id format (should return 400)
- ❌ Empty currency (should return 400)
- ❌ Invalid currency - uppercase (should return 400)
- ❌ Invalid currency - special characters (should return 400)
- ❌ Non-existent transaction ID (should return 404)
- ❌ Invalid UUID format (should return 400)

---

## Configuration

### Changing the Base URL

**JetBrains:**
Edit `curls/jetbrains/http-client.env.json`:
```json
{
  "dev": {
    "baseUrl": "http://your-server:8080"
  }
}
```

**Postman:**
1. Click on "Environments" in the left sidebar
2. Select "Ledger Service - Local"
3. Edit the `baseUrl` variable
4. Click "Save"

### Using Different Environments

You can create additional environments for different deployment stages:

**JetBrains:** Add to `http-client.env.json`:
```json
{
  "dev": { ... },
  "staging": {
    "baseUrl": "https://staging.example.com"
  },
  "production": {
    "baseUrl": "https://api.example.com"
  }
}
```

**Postman:** Duplicate the environment and modify values.

---

## Sample Transaction Data

The collections use the following sample UUIDs for testing:

- `550e8400-e29b-41d4-a716-446655440000` - Primary test user
- `123e4567-e89b-12d3-a456-426614174000` - Secondary test user
- `f47ac10b-58cc-4372-a567-0e02b2c3d479` - Tertiary test user

Currencies used:
- `usd` - US Dollar
- `brl` - Brazilian Real
- `eur` - Euro
- `loyalty_points` - Custom currency example
- `reward_tokens` - Custom currency example

---

## Tips and Best Practices

### JetBrains HTTP Client

1. **Keyboard Shortcuts**:
   - `Ctrl+Enter` / `Cmd+Return` - Run request at cursor
   - `Ctrl+\` / `Cmd+\` - Navigate between requests

2. **Response History**:
   - All responses are saved automatically
   - Access via the "Show HTTP Requests History" button

3. **Scratch Files**:
   - Create `.http` files anywhere in your project
   - Use `@name = value` for file-scoped variables

### Postman

1. **Collection Runner**:
   - Use for automated testing
   - Configure delays between requests
   - Export results for CI/CD

2. **Pre-request Scripts**:
   - Generate dynamic data (timestamps, random UUIDs)
   - Set up authentication tokens

3. **Console**:
   - Open Postman Console (View → Show Postman Console)
   - See all request/response details
   - Debug test scripts

---

## Troubleshooting

### Connection Refused

**Problem**: `Failed to connect to localhost:8080`

**Solution**:
1. Ensure the ledger service is running: `make run` or `go run cmd/server/main.go`
2. Check if port 8080 is available: `lsof -i :8080` (Linux/Mac)
3. Verify the baseUrl in your environment configuration


### UUID Validation Errors

**Problem**: `invalid UUID format` error

**Solution**:
1. Ensure UUIDs are lowercase hexadecimal
2. Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
3. Use proper UUID v4 format

### 404 Not Found

**Problem**: Transaction ID not found

**Solution**:
1. Run a "Create Transaction" request first
2. The transaction ID is automatically captured
3. Ensure the service database is initialized

---

## Contributing

When adding new endpoints:

1. **JetBrains**: Add new request blocks to `ledger-api.http`
   - Use `###` separator
   - Add response handlers with tests
   - Document the purpose in comments

2. **Postman**: Add new requests to the collection
   - Place in appropriate folder
   - Add test scripts
   - Include descriptions

---

## Resources

- **JetBrains HTTP Client Documentation**: https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html
- **Postman Documentation**: https://learning.postman.com/docs/
- **Ledger Service API Specification**: See `tests/TEST_SPECIFICATION.md`
- **Ledger Service README**: See `README.md` in project root

---

## Version History

- **v1.0** (2025-12-20) - Initial collection with all CRUD operations and validation tests

