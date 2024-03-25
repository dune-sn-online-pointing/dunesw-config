import math

# Provided values
x = 0.5387660929040722
y = -0.20967658453381258
z = -0.8159453578733784

# Calculate magnitude
magnitude = math.sqrt(x**2 + y**2 + z**2)

# Check if magnitude is approximately equal to 1
if math.isclose(magnitude, 1):
    print("The provided values represent a unit vector.")
    print (magnitude)
else:
    print("The provided values do not represent a unit vector.")