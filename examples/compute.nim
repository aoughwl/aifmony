proc fib(n: int): int =
  if n < 2: return n
  return fib(n - 1) + fib(n - 2)

proc ack(m, n: int): int =
  if m == 0: return n + 1
  if n == 0: return ack(m - 1, 1)
  return ack(m - 1, ack(m, n - 1))

let a = fib(12)
let b = ack(2, 3)
