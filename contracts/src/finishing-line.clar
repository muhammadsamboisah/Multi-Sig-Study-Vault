;; finishing-line.clar (Clarity v2)
;; Enforces study group deadlines, consensus signaling, and accounting for refunds/forfeits.
;; Note: This MVP tracks amounts and state; STX transfers and multisig integration are deferred.

;; Error codes
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_EXISTS u409)
(define-constant ERR_BAD_STATE u400)
(define-constant ERR_FORBIDDEN u403)
(define-constant ERR_NO_CONSENSUS u412)

;; Groups by id
;; - deadline: block height when group closes
;; - threshold: number of members required to reach consensus
;; - multisig: external multisig principal (GRAFT)
;; - dao: DAO pool principal to receive forfeits
;; - closed: true when settled via consensus or forfeit
(define-map groups
  { group-id: uint }
  { deadline: uint, threshold: uint, multisig: principal, dao: principal, closed: bool }
)

;; Member deposits (accounting only)
(define-map deposits
  { group-id: uint, member: principal }
  { amount: uint, refunded: bool }
)

;; Consensus votes (one per member)
(define-map votes
  { group-id: uint, member: principal }
  { signaled: bool }
)

;; Vote counts per group
(define-map vote-counts
  { group-id: uint }
  { count: uint }
)

;; Group pool accounting (no real custody in MVP)
(define-map pool-balances
  { group-id: uint }
  { balance: uint, forfeited: bool }
)

;; Read group info (optional)
;; finishing-line.clar
;; Enforces study group deadline, consensus, and fund flows.
;; MVP avoids iteration by tracking per-member state and group signal counters.

;; DAO pool destination (to be restricted by admin in future iterations)
(define-data-var dao-pool principal 'ST000000000000000000002AMW42H)

;; group-id -> group info
(define-map groups
  { id: uint }
  { deadline: uint, threshold: uint, multisig: principal, signals: uint, finalized: bool }
)

;; (id, member) -> deposit
(define-map deposits
  { id: uint, member: principal }
  { amount: uint, claimed: bool }
)

;; (id, member) -> whether member signaled consensus
(define-map votes
  { id: uint, member: principal }
  { yes: bool }
)

;; Admin: set DAO pool address (open for MVP; restrict later)
(define-public (set-dao-pool (p principal))
  (begin
    (var-set dao-pool p)
    (ok true)
  )
)

(define-read-only (get-group (id uint))
  (match (map-get? groups { id: id })
    g (ok g)
    (err u404)
  )
)

(define-read-only (has-consensus (id uint))
  (let (
        (g (unwrap! (map-get? groups { id: id }) (err u404)))
       )
    (ok (>= (get signals g) (get threshold g)))
  )
)

;; Create group with deadline (block-height), threshold (num of yes votes), and multisig principal
(define-public (create-group (id uint) (deadline uint) (threshold uint) (multisig principal))
  (begin
    (asserts! (is-none (map-get? groups { id: id })) (err u409))
    (map-set groups { id: id } { deadline: deadline, threshold: threshold, multisig: multisig, signals: u0, finalized: false })
    (ok true)
  )
)

;; Deposit amount (accounting only in MVP) for given group
(define-public (deposit (id uint) (amount uint))
  (let (
        (g (unwrap! (map-get? groups { id: id }) (err u404)))
        (sender tx-sender)
       )
    (begin
      (asserts! (<= block-height (get deadline g)) (err u400))
      (match (map-get? deposits { id: id, member: sender })
        existing (let ((new-amt (+ (get amount existing) amount)))
                   (map-set deposits { id: id, member: sender } { amount: new-amt, claimed: (get claimed existing) })
                   (ok true))
        none (begin
               (map-set deposits { id: id, member: sender } { amount: amount, claimed: false })
               (ok true)
             )
      )
    )
  )
)

;; Member signals consensus for refund; counts once per member
(define-public (signal (id uint))
  (let (
        (g (unwrap! (map-get? groups { id: id }) (err u404)))
       )
    (begin
      (asserts! (<= block-height (get deadline g)) (err u400))
      (match (map-get? votes { id: id, member: tx-sender })
        existing (ok true) ;; already signaled; idempotent
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

;; Refund caller's deposit (accounting only in MVP) if consensus met and before finalization
(define-public (claim-refund (id uint) (recipient principal)) ;; recipient reserved for later STX transfer
  (let (
        (g (unwrap! (map-get? groups { id: id }) (err u404)))
        (d (unwrap! (map-get? deposits { id: id, member: tx-sender }) (err u404)))
       )
    (begin
      (asserts! (<= block-height (get deadline g)) (err u400))
      (asserts! (is-eq (get finalized g) false) (err u409))
      (asserts! (is-eq (get claimed d) false) (err u409))
      (match (has-consensus id)
        cons-ok (asserts! cons-ok (err u412))
        cons-err (err cons-err)
      )
      (map-set deposits { id: id, member: tx-sender } { amount: (get amount d), claimed: true })
  (ok true)
    )
  )
)

;; After deadline, member can forfeit their unclaimed deposit to DAO pool (accounting-only in MVP)
(define-public (forfeit-self (id uint))
  (let (
        (g (unwrap! (map-get? groups { id: id }) (err u404)))
        (d (unwrap! (map-get? deposits { id: id, member: tx-sender }) (err u404)))
       )
    (begin
      (asserts! (> block-height (get deadline g)) (err u400))
      (asserts! (is-eq (get claimed d) false) (err u409))
      (map-set deposits { id: id, member: tx-sender } { amount: (get amount d), claimed: true })
  (ok true)
    )
  )
)
