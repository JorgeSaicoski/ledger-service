package repository

import (
	"context"
	"fmt"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// TransactionRepository defines the interface for transaction data operations
type TransactionRepository interface {
	Create(ctx context.Context, req models.TransactionRequest) (string, error)
	GetByID(ctx context.Context, id string) (*models.Transaction, error)
	ListByUser(ctx context.Context, userID string, currency *string, limit, offset int) ([]models.Transaction, error)
}

// PostgresTransactionRepository implements TransactionRepository using PostgreSQL
type PostgresTransactionRepository struct {
	db *pgxpool.Pool
}

// NewPostgresTransactionRepository creates a new PostgreSQL repository
func NewPostgresTransactionRepository(db *pgxpool.Pool) *PostgresTransactionRepository {
	return &PostgresTransactionRepository{db: db}
}

// Create creates a new transaction in the database
func (r *PostgresTransactionRepository) Create(ctx context.Context, req models.TransactionRequest) (string, error) {
	query := `
		INSERT INTO transactions (user_id, amount, currency) 
		VALUES ($1, $2, $3) 
		RETURNING id
	`
	var id string
	err := r.db.QueryRow(ctx, query, req.UserID, req.Amount, req.Currency).Scan(&id)
	if err != nil {
		return "", err
	}
	return id, nil
}

// GetByID retrieves a transaction by its ID
func (r *PostgresTransactionRepository) GetByID(ctx context.Context, id string) (*models.Transaction, error) {
	query := `
		SELECT id, user_id, amount, currency, timestamp 
		FROM transactions
		WHERE id = $1
	`
	var transaction models.Transaction
	err := r.db.QueryRow(ctx, query, id).Scan(&transaction.ID, &transaction.UserID, &transaction.Amount, &transaction.Currency, &transaction.Timestamp)
	if err != nil {
		return nil, err
	}
	return &transaction, nil
}

// ListByUser retrieves all transactions for a user with an optional currency filter
func (r *PostgresTransactionRepository) ListByUser(ctx context.Context, userID string, currency *string, limit, offset int) ([]models.Transaction, error) {
	query := `
	  SELECT id, user_id, amount, currency, timestamp
	  FROM transactions
	  WHERE user_id = $1
	 `
	args := []interface{}{userID}

	if currency != nil && *currency != "" {
		query += ` AND currency = $2`
		args = append(args, *currency)
	}

	query += ` ORDER BY timestamp DESC LIMIT $` + fmt.Sprintf("%d", len(args)+1) + ` OFFSET $` + fmt.Sprintf("%d", len(args)+2)
	args = append(args, limit, offset)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return r.scanTransactions(rows)
}

func (r *PostgresTransactionRepository) scanTransactions(rows pgx.Rows) ([]models.Transaction, error) {
	var transactions []models.Transaction
	for rows.Next() {
		var t models.Transaction
		err := rows.Scan(&t.ID, &t.UserID, &t.Amount, &t.Currency, &t.Timestamp)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, t)
	}
	return transactions, rows.Err()
}
