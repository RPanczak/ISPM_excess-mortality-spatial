library(INLA)

getwd()

n = 100; a = 1; b = 1; tau = 100
z = rnorm(n)
eta = a + b*z

scale = exp(rnorm(n))
prec = scale*tau
y = rnorm(n, mean = eta, sd = 1/sqrt(prec))


data = list(y=y, z=z)
data
formula = y ~ 1+z
formula

result = inla(formula, family = "gaussian", data = data, verbose = TRUE)

summary(result)

getwd()
