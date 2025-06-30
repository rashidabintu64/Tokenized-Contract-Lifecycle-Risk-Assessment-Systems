;; Contract Risk Analyst Verification System
;; Validates and manages contract risk analysts

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ANALYST_EXISTS (err u101))
(define-constant ERR_ANALYST_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CERTIFICATION (err u103))

;; Data Variables
(define-data-var next-analyst-id uint u1)

;; Data Maps
(define-map analysts
  { analyst-id: uint }
  {
    address: principal,
    certification-level: uint,
    specialization: (string-ascii 50),
    verified-at: uint,
    active: bool,
    total-assessments: uint,
    success-rate: uint
  }
)

(define-map analyst-by-address
  { address: principal }
  { analyst-id: uint }
)

(define-map certifications
  { cert-id: uint }
  {
    name: (string-ascii 100),
    required-level: uint,
    valid-duration: uint
  }
)

;; Public Functions

;; Register a new analyst
(define-public (register-analyst (address principal) (certification-level uint) (specialization (string-ascii 50)))
  (let ((analyst-id (var-get next-analyst-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? analyst-by-address { address: address })) ERR_ANALYST_EXISTS)
    (asserts! (>= certification-level u1) ERR_INVALID_CERTIFICATION)

    (map-set analysts
      { analyst-id: analyst-id }
      {
        address: address,
        certification-level: certification-level,
        specialization: specialization,
        verified-at: block-height,
        active: true,
        total-assessments: u0,
        success-rate: u100
      }
    )

    (map-set analyst-by-address
      { address: address }
      { analyst-id: analyst-id }
    )

    (var-set next-analyst-id (+ analyst-id u1))
    (ok analyst-id)
  )
)

;; Verify analyst credentials
(define-public (verify-analyst (analyst-id uint))
  (let ((analyst (unwrap! (map-get? analysts { analyst-id: analyst-id }) ERR_ANALYST_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set analysts
      { analyst-id: analyst-id }
      (merge analyst { verified-at: block-height })
    )
    (ok true)
  )
)

;; Update analyst performance metrics
(define-public (update-analyst-metrics (analyst-id uint) (assessments-completed uint) (success-rate uint))
  (let ((analyst (unwrap! (map-get? analysts { analyst-id: analyst-id }) ERR_ANALYST_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set analysts
      { analyst-id: analyst-id }
      (merge analyst {
        total-assessments: (+ (get total-assessments analyst) assessments-completed),
        success-rate: success-rate
      })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get analyst information
(define-read-only (get-analyst (analyst-id uint))
  (map-get? analysts { analyst-id: analyst-id })
)

;; Get analyst by address
(define-read-only (get-analyst-by-address (address principal))
  (match (map-get? analyst-by-address { address: address })
    analyst-ref (map-get? analysts { analyst-id: (get analyst-id analyst-ref) })
    none
  )
)

;; Check if analyst is verified and active
(define-read-only (is-analyst-verified (analyst-id uint))
  (match (map-get? analysts { analyst-id: analyst-id })
    analyst (and (get active analyst) (> (get verified-at analyst) u0))
    false
  )
)
