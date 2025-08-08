;; finishing-line.clar (Clarity v2)
;; Enforces study group deadlines, consensus signaling, and accounting for refunds/forfeits.
;; MVP: accounting-only (no STX transfers or multisig calls yet).

;; Defaults and errors
(define-data-var dao-pool principal 'ST000000000000000000002AMW42H)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_EXISTS u409)
(define-constant ERR_BAD_STATE u400)
(define-constant ERR_NO_CONSENSUS u412)

;; Groups by id
(define-map groups
  { id: uint }
  { deadline: uint, threshold: uint, multisig: principal, signals: uint, finalized: bool }
)

;; Deposits per member (accounting only)
(define-map deposits
  { id: uint, member: principal }
  { amount: uint, claimed: bool }
)

;; Member signals
(define-map votes
  { id: uint, member: principal }
  { yes: bool }
)

;; Admin: set DAO pool
(define-public (set-dao-pool (p principal))
  (begin (var-set dao-pool p) (ok true))
)

(define-read-only (get-group (id uint))
  (match (map-get? groups { id: id }) g (ok g) (err ERR_NOT_FOUND))
)

(define-read-only (has-consensus (id uint))
  (let ((g (unwrap! (map-get? groups { id: id }) (err ERR_NOT_FOUND))))
    (ok (>= (get signals g) (get threshold g)))
  )
)

;; Create group
(define-public (create-group (id uint) (deadline uint) (threshold uint) (multisig principal))
  (begin
    (asserts! (is-none (map-get? groups { id: id })) (err ERR_EXISTS))
    (map-set groups { id: id } { deadline: deadline, threshold: threshold, multisig: multisig, signals: u0, finalized: false })
    (ok true)
  )
)

;; Deposit amount (accounting only)
(define-public (deposit (id uint) (amount uint))
  (let ((g (unwrap! (map-get? groups { id: id }) (err ERR_NOT_FOUND)))
        (sender tx-sender))
    (begin
      (asserts! (<= (block-height) (get deadline g)) (err ERR_BAD_STATE))
      (match (map-get? deposits { id: id, member: sender })
        existing (let ((new-amt (+ (get amount existing) amount)))
                   (map-set deposits { id: id, member: sender } { amount: new-amt, claimed: (get claimed existing) })
                   (ok true))
        none (begin (map-set deposits { id: id, member: sender } { amount: amount, claimed: false }) (ok true))
      )
    )
  )
)

;; Signal consensus (idempotent)
(define-public (signal (id uint))
  (let ((g (unwrap! (map-get? groups { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (<= (block-height) (get deadline g)) (err ERR_BAD_STATE))
      (match (map-get? votes { id: id, member: tx-sender })
        existing (ok true)
        none (begin
               (map-set votes { id: id, member: tx-sender } { yes: true })
               (let ((new-s (+ (get signals g) u1)))
                 (map-set groups { id: id } { deadline: (get deadline g), threshold: (get threshold g), multisig: (get multisig g), signals: new-s, finalized: (get finalized g) })
                 (ok true)
               )
             )
      )
    )
  )
)

;; Claim refund (accounting only)
(define-public (claim-refund (id uint) (recipient principal))
  (let ((g (unwrap! (map-get? groups { id: id }) (err ERR_NOT_FOUND)))
        (d (unwrap! (map-get? deposits { id: id, member: tx-sender }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (<= (block-height) (get deadline g)) (err ERR_BAD_STATE))
      (asserts! (is-eq (get finalized g) false) (err ERR_EXISTS))
      (asserts! (is-eq (get claimed d) false) (err ERR_EXISTS))
      (match (has-consensus id)
        cons-ok (asserts! cons-ok (err ERR_NO_CONSENSUS))
        cons-err (err cons-err)
      )
      (map-set deposits { id: id, member: tx-sender } { amount: (get amount d), claimed: true })
      (ok true)
    )
  )
)

;; Forfeit after deadline (accounting only)
(define-public (forfeit-self (id uint))
  (let ((g (unwrap! (map-get? groups { id: id }) (err ERR_NOT_FOUND)))
        (d (unwrap! (map-get? deposits { id: id, member: tx-sender }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (> (block-height) (get deadline g)) (err ERR_BAD_STATE))
      (asserts! (is-eq (get claimed d) false) (err ERR_EXISTS))
      (map-set deposits { id: id, member: tx-sender } { amount: (get amount d), claimed: true })
      (ok true)
    )
  )
)
