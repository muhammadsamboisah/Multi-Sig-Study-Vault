;; finishing-line.clar
;; Enforces a study group's deadline, consensus, and fund flows per PRD.

(define-data-var dao-pool <principal> tx-sender)

(define-trait i-ft-transfer
  (
    (transfer (uint principal principal) (response bool uint))
  )
)

(define-map deposits
  { group-id: uint, member: principal }
  { amount: uint, refunded: bool }
)

(define-map consensus
  { group-id: uint, member: principal }
  { signaled: bool }
)

(define-map groups
  { group-id: uint }
  { deadline: uint, threshold: uint, multisig: principal }
)

(define-data-var group-pool { group-id: uint } uint)

(define-read-only (get-group (group-id uint))
  (match (map-get? groups { group-id: group-id })
    group group
    (err u404)
  )
)

(define-private (is-before-deadline (deadline uint))
  (< (var-get block-height) deadline)
)

(define-read-only (has-consensus (group-id uint))
  (let
    (
      (grp (unwrap-panic (map-get? groups { group-id: group-id })))
      (m (unwrap-panic (map-get? consensus { group-id: group-id, member: tx-sender })))
    )
    (ok (>= (get threshold grp) (len (filter consensus (fn (c) (get signaled c)) group-id))))
  )
)

(define-public (create-group (group-id uint) (deadline uint) (threshold uint) (multisig principal))
  (begin
    (asserts! (is-none (map-get? groups { group-id: group-id })) (err u409))
    (map-set groups { group-id: group-id } { deadline: deadline, threshold: threshold, multisig: multisig })
    (ok true)
  )
)

(define-public (deposit (group-id uint))
  (let
    (
      (grp (unwrap! (map-get? groups { group-id: group-id }) (err u404)))
    )
    (begin
      (asserts! (<= (block-height) (get deadline grp)) (err u400))
      ;; For STX deposit, transfer via contract-call is implicit with payable - to be wired with
      ;; clarity version and trait if using SIP-010 token. Placeholder records deposit.
      (map-set deposits { group-id: group-id, member: tx-sender } { amount: u0, refunded: false })
      (ok true)
    )
  )
)

(define-public (signal-consensus (group-id uint))
  (let
    (
      (grp (unwrap! (map-get? groups { group-id: group-id }) (err u404)))
    )
    (begin
      (asserts! (<= (block-height) (get deadline grp)) (err u400))
      (map-set consensus { group-id: group-id, member: tx-sender } { signaled: true })
      (ok true)
    )
  )
)

(define-public (claim-refund (group-id uint) (recipient principal))
  (let
    (
      (grp (unwrap! (map-get? groups { group-id: group-id }) (err u404)))
      (dep (unwrap! (map-get? deposits { group-id: group-id, member: tx-sender }) (err u404)))
    )
    (begin
      (asserts! (<= (block-height) (get deadline grp)) (err u400))
      (asserts! (is-ok (has-consensus group-id)) (err u412))
      (asserts! (is-eq (get refunded dep) false) (err u409))
      (map-set deposits { group-id: group-id, member: tx-sender } { amount: (get amount dep), refunded: true })
      ;; Placeholder: would transfer STX from multisig back to recipient via GRAFT/multisig
      (ok true)
    )
  )
)

(define-public (forfeit-to-dao (group-id uint))
  (let
    (
      (grp (unwrap! (map-get? groups { group-id: group-id }) (err u404)))
    )
    (begin
      (asserts! (> (block-height) (get deadline grp)) (err u400))
      ;; Placeholder: transfer all undistributed funds to dao-pool
      (ok true)
    )
  )
)
