;; Institution Verification Contract
;; Validates consciousness spirituality providers

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions
  { institution-id: (string-ascii 64) }
  {
    name: (string-utf8 256),
    description: (string-utf8 1024),
    website: (string-ascii 256),
    verified-date: uint,
    status: (string-ascii 16)
  }
)

;; Public function to verify an institution (admin only)
(define-public (verify-institution
    (institution-id (string-ascii 64))
    (name (string-utf8 256))
    (description (string-utf8 1024))
    (website (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set verified-institutions
      { institution-id: institution-id }
      {
        name: name,
        description: description,
        website: website,
        verified-date: block-height,
        status: "verified"
      }
    )
    (ok true)
  )
)

;; Public function to revoke verification (admin only)
(define-public (revoke-verification (institution-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-delete verified-institutions { institution-id: institution-id })
    (ok true)
  )
)

;; Read-only function to check if an institution is verified
(define-read-only (is-verified (institution-id (string-ascii 64)))
  (is-some (map-get? verified-institutions { institution-id: institution-id }))
)

;; Read-only function to get institution details
(define-read-only (get-institution-details (institution-id (string-ascii 64)))
  (map-get? verified-institutions { institution-id: institution-id })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
