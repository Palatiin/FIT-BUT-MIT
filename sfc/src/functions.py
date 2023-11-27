# File: functions.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Definition of activation functions

import datetime as dt

import numpy as np


class ActivationFunction:
    """Base class for activation functions."""
    @staticmethod
    def forward(x: np.ndarray) -> np.ndarray:
        """Evaluate activation function."""
        raise NotImplementedError()

    @staticmethod
    def backward(x: np.ndarray) -> np.ndarray:
        raise NotImplementedError()


class BaseFunction:
    """Base class for base functions: Linear / Radial (not implemented)."""
    def __init__(self, input_dim: int, output_dim: int):
        self.input_dim: int = input_dim
        self.output_dim: int = output_dim
        self.weight: np.ndarray = np.zeros((input_dim, output_dim))
        self.bias: np.ndarray = np.zeros(output_dim)

    def __call__(self, x: np.ndarray) -> np.ndarray:
        raise NotImplementedError()

    def init_weights(self, activation: ActivationFunction):
        # https://machinelearningmastery.com/weight-initialization-for-deep-learning-neural-networks/

        np.random.seed(int(dt.datetime.now().timestamp()))
        if activation.__class__.__name__ == "Sigmoid":
            # normalized Xavier initialization
            bound = np.sqrt(6.0) / np.sqrt(self.input_dim + self.output_dim)
            bounds = (-bound, bound)
            self.weight = np.random.rand(self.input_dim, self.output_dim) * (bounds[1] - bounds[0]) + bounds[0]
        elif activation.__class__.__name__ == "ReLU":
            # He initialization
            std: float = np.sqrt(2.0 / self.input_dim)
            self.weight = np.random.randn(self.input_dim, self.output_dim) * std
        else:
            self.weight = np.random.uniform(low=-0.5, high=0.5, size=(self.input_dim, self.output_dim))


class Linear(BaseFunction):
    """Linear base function: u = sum(w * x) + b"""
    def __init__(self, input_dim: int, output_dim: int):
        super().__init__(input_dim, output_dim)

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """Evaluate base function."""
        return np.dot(x, self.weight) + self.bias


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
