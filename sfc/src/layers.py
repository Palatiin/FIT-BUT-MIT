# File: layers.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Definition of model layers

import numpy as np

from .functions import BaseFunction, ActivationFunction


class Layer:
    """Layer of neural network."""

    def __init__(self, base: BaseFunction, activation: ActivationFunction):
        self.base: BaseFunction = base
        self.base.init_weights(activation)
        self.activation: ActivationFunction = activation

    @property
    def weights(self) -> np.ndarray:
        return self.base.weight

    @weights.setter
    def weights(self, value: np.ndarray) -> None:
        self.base.weight = value

    @property
    def biases(self) -> np.ndarray:
        return self.base.bias

    @biases.setter
    def biases(self, value: np.ndarray) -> None:
        self.base.bias = value

    def forward(self, x: np.ndarray) -> np.ndarray:
        """Performs function: y = f(u(x))

        * x - input
        * y - output
        * u - base function
        * f - activation function
        """
        return self.activation.forward(self.base(x))

    def backward(self, x: np.ndarray) -> np.ndarray:
        """Derivative of activation function."""
        return self.activation.backward(x)
