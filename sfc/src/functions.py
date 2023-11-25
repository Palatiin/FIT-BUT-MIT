# File: functions.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Definition of activation functions

import numpy as np


class BaseFunction:
    def __init__(self, input_dim: int, output_dim: int):
        np.random.seed(420)
        # initialize weights in range [-0.5, 0.5]
        self.weight: np.ndarray = np.random.rand(input_dim, output_dim) - 0.5
        self.bias: np.ndarray = np.zeros(output_dim)

    def __call__(self, x: np.ndarray) -> np.ndarray:
        raise NotImplementedError()


class Linear(BaseFunction):
    def __init__(self, input_dim: int, output_dim: int):
        super().__init__(input_dim, output_dim)
        self.y: float = 0.0

    def __call__(self, x: np.ndarray) -> np.ndarray:
        return np.dot(x, self.weight) + self.bias


class ActivationFunction:
    @staticmethod
    def forward(x: np.ndarray) -> np.ndarray:
        raise NotImplementedError()

    @staticmethod
    def backward(x: np.ndarray) -> np.ndarray:
        raise NotImplementedError()


class Sigmoid(ActivationFunction):
    @staticmethod
    def forward(x: np.ndarray) -> np.ndarray:
        return 1.0 / (1.0 + np.exp(-x))

    @staticmethod
    def backward(x: np.ndarray) -> np.ndarray:
        """Derivative of sigmoid function."""
        return x * (1.0 - x)


class ReLU(ActivationFunction):
    @staticmethod
    def forward(x: np.ndarray) -> np.ndarray:
        return np.maximum(0, x)

    @staticmethod
    def backward(x: np.ndarray) -> np.ndarray:
        """Derivative of ReLU function."""
        return np.where(x > 0, 1, 0)
