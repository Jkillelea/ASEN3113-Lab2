function val = u(x, t, b, l, alpha, H, T0, N)

  val = T0 + H.*x;
  for n = 1:N
    val = val + b(n).*sin(l(n).*x).*exp(-l(n)^2.*alpha.*t);
  end
end
