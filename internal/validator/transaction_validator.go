package validator

import (
	"errors"
	"regexp"

	"github.com/bardockgaucho/ledger-service/internal/models"
)

var (
	// ErrUserIDEmpty indicates user_id is empty
	ErrUserIDEmpty = errors.New("user_id cannot be empty")
	// ErrCurrencyEmpty indicates currency is empty
	ErrCurrencyEmpty = errors.New("currency cannot be empty")
	// ErrCurrencyInvalid indicates currency format is invalid
	ErrCurrencyInvalid = errors.New("currency must be alphanumeric and max 32 characters")
	// ErrAmountInvalid indicates amount is not a valid number
	ErrAmountInvalid = errors.New("amount must be a valid number")
	// ErrUUIDInvalid indicates UUID format is invalid
	ErrUUIDInvalid = errors.New("invalid UUID format")
)

// TransactionValidator handles validation of transaction data
type TransactionValidator struct {
	currencyRegex *regexp.Regexp
	uuidRegex     *regexp.Regexp
}

// NewTransactionValidator creates a new validator instance
func NewTransactionValidator() *TransactionValidator {
	return &TransactionValidator{
		currencyRegex: regexp.MustCompile(`^[a-z0-9_]{1,32}$`),
		uuidRegex:     regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$`),
	}
}

// ValidateTransactionRequest validates a transaction creation request
func (v *TransactionValidator) ValidateTransactionRequest(req models.TransactionRequest) error {
	if err := v.validateUserID(req.UserID); err != nil {
		return err
	}
	if err := v.validateCurrency(req.Currency); err != nil {
		return err
	}
	return nil
}

// validateUserID validates user_id format
func (v *TransactionValidator) validateUserID(userID string) error {
	if userID == "" {
		return ErrUserIDEmpty
	}
	return nil
}

// ValidateCurrency validates currency format
func (v *TransactionValidator) validateCurrency(currency string) error {
	if currency == "" {
		return ErrCurrencyEmpty
	}
	if !v.currencyRegex.MatchString(currency) {
		return ErrCurrencyInvalid
	}
	return nil
}

// ValidateUUID validates UUID format
func (v *TransactionValidator) ValidateUUID(id string) error {
	if !v.uuidRegex.MatchString(id) {
		return ErrUUIDInvalid
	}
	return nil
}
