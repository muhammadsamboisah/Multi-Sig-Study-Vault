;; dao-pool.clar (Clarity v2)
;; Tracks forfeited balances per group (accounting only in MVP)

(define-map forfeits
  { group-id: uint }
  { total: uint }
)

(define-read-only (get-forfeit-total (group-id uint))
  (match (map-get? forfeits { group-id: group-id })
    f (get total f)
    u0
  )
)

(define-public (record-forfeit (group-id uint) (amount uint) (from principal))
  (begin
    (let ((current (get-forfeit-total group-id)))
      (map-set forfeits { group-id: group-id } { total: (+ current amount) })
    )
    (ok true)
  )
)
