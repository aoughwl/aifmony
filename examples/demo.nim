import std/syncio

proc fib(n: int): int =
  if n < 2: return n
  return fib(n - 1) + fib(n - 2)

proc fact(n: int): int =
  result = 1
  for i in 2 .. n:
    result = result * i

proc isPrime(n: int): bool =
  if n < 2: return false
  var i = 2
  while i * i <= n:
    if n mod i == 0: return false
    i = i + 1
  return true

echo fib(20)
echo fact(10)
echo isPrime(97)
