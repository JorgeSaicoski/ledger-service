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
- user_id (string, required)
- amount (decimal, can be negative)
- currency (string, required) - e.g., "usd", "brl", "loyalty_points"
- timestamp (auto-generated)
```

## API Endpoints

### POST /transactions
Create a new transaction

**Request:**
```json
{
  "user_id": "user123",
  "amount": -50.00,
  "currency": "usd"
}
```

**Response:**
```json
{
  "id": "uuid",
  "user_id": "user123",
  "amount": -50.00,
  "currency": "usd",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### GET /transactions?user_id={id}&currency={currency}
Get all transactions for a user in specific currency

**Response:**
```json
{
  "transactions": [
    {
      "id": "uuid1",
      "user_id": "user123",
      "amount": 100.00,
      "currency": "usd",
      "timestamp": "2025-01-15T10:00:00Z"
    },
    {
      "id": "uuid2",
      "user_id": "user123",
      "amount": -50.00,
      "currency": "usd",
      "timestamp": "2025-01-15T10:30:00Z"
    }
  ]
}
```

### GET /balance?user_id={id}&currency={currency}
Get current balance for user in specific currency

**Response:**
```json
{
  "user_id": "user123",
  "currency": "usd",
  "balance": 50.00
}
```

### GET /balance?user_id={id}
Get all balances for user across all currencies

**Response:**
```json
{
  "user_id": "user123",
  "balances": [
    {"currency": "usd", "balance": 50.00},
    {"currency": "loyalty_points", "balance": 125.00}
  ]
}
```

## Use Cases

### Personal Finance Tracking
User logs expenses and income. Calculator service sums transactions for budget reports.

### Cafe Loyalty System
- Customer buys coffee → cashier service creates transaction: +10 loyalty_points
- Customer redeems points → cashier service creates transaction: -10 loyalty_points
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

## Database

PostgreSQL
- ACID guarantees for financial data
- Simple schema
- Easy querying and aggregation

## Error Handling

**400 Bad Request** - Invalid input (missing required fields, invalid amount)
**404 Not Found** - User has no transactions
**500 Internal Server Error** - Database issues

## Future Considerations

When scale requires it (not at 10-20 users):
- Add pagination to transaction listing
- Add date range filtering
- Add caching for balance calculations
- Add read replicas for query performance

## For Developers

This service should be understandable in 5 minutes. If it's not, we're doing it wrong.

- Single table in database
- Four simple endpoints
- No complex business logic
- All complexity lives in consuming services
