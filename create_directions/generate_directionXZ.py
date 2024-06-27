# generate a random theta angle using arcos function and random number generator

import numpy as np
import random

def generate_angles():  
    # generate a random number between 0 and 1
    r1 = random.random()
    r2 = random.random()
    # print (r)
    # generate a random theta angle using arcos function
    theta = np.arccos(1 - 2*r1)
    phi = 2*np.pi*r2
    # print (phi)
    return(phi, theta)

phi, theta = generate_angles()

x = np.sin(theta)*np.cos(phi)
y = 0
z = np.cos(theta)

#normalize the vector
module = np.sqrt(x**2  + z**2)
x = x/module
z = z/module

print (x)
print (y)
print (z)

# print length of vector, don't uncomment of script custom-direction.sh will not work
# print (np.sqrt(x**2 + y**2 + z**2))