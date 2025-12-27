# Transaction Ledger Service

A simple, reusable microservice for recording financial movements. Does one thing: stores transactions.

## What This Service Does

- Receives transaction data (user_id, amount, currency)
- Stores it with timestamp
- Returns transaction_id
- Calculates balances per user per currency

## What This Service Does NOT Do

- User management (assumes user_id exists)
- Business logic (rewards, multipliers, categories)
- Transaction linking (grouping related transactions)
- Budget enforcement
- Analytics

Those are responsibilities of consuming services.

## Core Concept

Every financial movement = one transaction record.
Transfers between users = two separate transactions.
Mistakes = new compensating transactions (never delete).

## Data Model

```
Transaction:
- id (uuid, auto-generated)
- user_id (string, required, lowercase UUID format)
- amount (integer, can be negative) - stored in smallest currency unit (cents/centavos)
- currency (string, required, lowercase) - e.g., "usd", "brl", "loyalty_points"
- timestamp (auto-generated)
```

**Important Format Requirements:**
- `user_id`: Must be a valid UUID in lowercase format (e.g., "550e8400-e29b-41d4-a716-446655440000")
- `currency`: Must be lowercase letters, numbers, and underscores only (e.g., "usd", "loyalty_points", "usd2024")
- Uppercase characters are **not accepted** and will result in a 400 Bad Request error

**Currency Amount Storage:**
- **USD, BRL**: Store in cents/centavos (e.g., 100 = $1.00 or R$1,00)
- **UYU**: Store in pesos (smallest unit, no subdivision)
- **Custom currencies**: Define your own smallest unit

This integer-based approach avoids floating-point precision issues and ensures accurate financial calculations.


## API Endpoints

### POST /transactions
Create a new transaction

**Request:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "amount": -5000,
  "currency": "usd"
}
```
*Note: Amount is -5000 cents = -$50.00*

**Note:** `user_id` must be a valid lowercase UUID format.

**Response:**
```json
{
  "id": "a1b2c3d4-e5f6-4890-abcd-ef1234567890",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "amount": -5000,
  "currency": "usd",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### GET /transactions?user_id={id}&currency={currency}
Get all transactions for a user in specific currency

**Note:** `user_id` parameter must be a valid lowercase UUID format.

**Response:**
```json
{
  "transactions": [
    {
      "id": "a1b2c3d4-e5f6-4890-abcd-ef1234567890",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "amount": 10000,
      "currency": "usd",
      "timestamp": "2025-01-15T10:00:00Z"
    },
    {
      "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "amount": -5000,
      "currency": "usd",
      "timestamp": "2025-01-15T10:30:00Z"
    }
  ]
}
```
*Note: Amounts are in cents (10000 cents = $100.00, -5000 cents = -$50.00)*

## Use Cases

### Personal Finance Tracking
User logs expenses and income. Calculator service sums transactions for budget reports.
Example: Log $15.50 coffee purchase as `amount: -1550` (in cents).

### Cafe Loyalty System
- Customer buys coffee → cashier service creates transaction: +1000 loyalty_points
- Customer redeems points → cashier service creates transaction: -1000 loyalty_points
- Customer transfers points → two transactions (one negative, one positive)

### Multi-User Financial System
- Transfer between users → calling service creates two transactions
- If transfer fails → calling service creates compensating transactions

## Technical Decisions

**Why no transaction deletion?**
Financial records are immutable. Mistakes are corrected with new transactions.

**Why no origin/destiny fields?**
Simplicity. Calling services handle relationships between transactions.

**Why no metadata/description?**
Single responsibility. Other services handle categorization and linking.

**Why positive/negative amounts instead of transaction types?**
Simpler math. Balance = SUM(amount). No conditional logic needed.

**Why integers instead of decimals?**
Avoids floating-point precision errors. Financial calculations must be exact. Store amounts in the smallest currency unit (cents, centavos, pesos).

## Database

PostgreSQL
- ACID guarantees for financial data
- Simple schema
- Easy querying and aggregation

## Error Handling

**400 Bad Request** - Invalid input (missing required fields, invalid format)
  - Missing required fields
  - Invalid UUID format (must be lowercase)
  - Invalid currency format (must be lowercase alphanumeric)
**404 Not Found** - User has no transactions
**500 Internal Server Error** - Database issues

## Future Considerations

When scale requires it (not at 10-20 users):
- Add pagination to transaction listing
- Add date range filtering
- Add caching for balance calculations
- Add read replicas for query performance

## Testing

This project follows **Test-Driven Development (TDD)** principles. Comprehensive automated tests are available in the `tests/` directory.

### Running Tests

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test suite
./tests/test_create_transaction.sh
./tests/test_balance.sh

# Run example API calls
./tests/examples.sh
```

### Test Coverage

- **20 comprehensive tests** covering all API endpoints
- Input validation (missing fields, invalid data)
- Functional tests (negative amounts, multiple currencies)
- Edge cases (empty results, pagination, integer precision)
- Security is handled at the API Gateway level (not tested in service layer)

See [tests/README.md](tests/README.md) for detailed documentation.

### CI/CD Integration

Tests are integrated into GitHub Actions workflow (`.github/workflows/tests.yml`). The workflow will automatically run tests on push and pull requests once the service is implemented.

## For Developers

This service should be understandable in 5 minutes. If it's not, we're doing it wrong.

- Single table in database
- Four simple endpoints
- No complex business logic
- All complexity lives in consuming services
- **Tests written first** following TDD approach
