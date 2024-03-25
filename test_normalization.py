import math

# Provided values
x = 0.3390741844716078
y = 0
z = 0.9407596384969511

# Calculate magnitude
magnitude = math.sqrt(x**2 + y**2 + z**2)

# Check if magnitude is approximately equal to 1
if math.isclose(magnitude, 1):
    print("The provided values represent a unit vector.")
    print (magnitude)
else:
    print("The provided values do not represent a unit vector.")