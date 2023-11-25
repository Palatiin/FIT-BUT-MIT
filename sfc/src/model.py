# File: model.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Autoencoder model class definition

from typing import List, Optional

import numpy as np

from .layers import Layer


class AutoencoderModel:
    """Autoencoder Deep Neural Network Model

    Autoencoder is a type of neural network that is learned to represent identity.
    This can be useful for pre-training of other deep neural networks. This autoencoder
    neural network has two layers, and is trained by backpropagation algorithm.
    """

    def __init__(self, layers: List[Layer], train_size: int, lr: float = 0.1):
        self.layers: List[Layer] = layers
        self.train_size: int = train_size
        self.learning_rate: float = lr

        self.error: List[float] = []

        # lists for mini-batch training ?
        self.hidden_output: List[np.ndarray] = []
        self.output: List[np.ndarray] = []

        self.train_error_evolution: List[float] = []
        self.test_error_evolution: List[float] = []

    @property
    def train_error_evo(self) -> np.array:
        return np.array(self.train_error_evolution)

    @property
    def test_error_evo(self) -> np.array:
        return np.array(self.test_error_evolution)

    def forward_pass(self, x: np.ndarray) -> np.ndarray:
        self.hidden_output.append(self.layers[0].forward(x))
        self.output.append(self.layers[1].forward(self.hidden_output[-1]))

        self.error.append(self.loss(self.output[-1], x) / self.train_size)

        return self.output[-1]

    def backward_pass(self, target: np.ndarray) -> None:
        # calculate weight deltas
        _error_output = self.output[-1] - target
        delta_output = _error_output * self.layers[1].backward(self.output[-1])

        _error_hidden = delta_output.dot(self.layers[1].weights.T)
        delta_hidden = _error_hidden * self.layers[0].backward(self.hidden_output[-1])

        # update weights
        self.layers[1].weights -= self.learning_rate * np.dot(self.hidden_output[-1].T, delta_output) / self.train_size
        self.layers[0].weights -= self.learning_rate * np.dot(target.T, delta_hidden) / self.train_size

        # prepare for next epoch
        self.error = []
        self.hidden_output, self.output = [], []

    def train(
        self, train_data: np.ndarray, test_data: Optional[np.ndarray] = None, epochs: Optional[int] = 20
    ) -> None:
        for epoch in range(epochs):
            np.random.shuffle(train_data)

            if test_data is not None:
                self.forward_pass(test_data)
                self.test_error_evolution.append(self.error[0])

            self.forward_pass(train_data)
            self.train_error_evolution.append(self.error[-1])

            print(f"Epoch: {epoch + 1} | Error: {self.error}")

            self.backward_pass(train_data)

    @staticmethod
    def loss(output: np.ndarray, target: np.ndarray) -> float:
        """Loss/Cost/Error function."""
        return 0.5 * np.sum((target - output) ** 2)
