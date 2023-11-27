# File: model.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Autoencoder model class definition

from typing import Generator, List, Optional

import numpy as np

from .layers import Layer


class AutoencoderModel:
    """Autoencoder Deep Neural Network Model

    Autoencoder is a type of neural network that is learned to represent identity.
    This can be useful for pre-training of other deep neural networks. Autoencoder
    neural network has two layers, and is trained by backpropagation algorithm.
    """

    BATCH_SIZE = 100

    def __init__(self, layers: List[Layer], lr: float = 0.1):
        self.layers: List[Layer] = layers
        self.learning_rate: float = lr

        self.error: List[float] = []

        # lists for mini-batch training ?
        self.hidden_output: List[np.ndarray] = []
        self.output: List[np.ndarray] = []

        self.train_error_evolution: List[float] = []
        self.test_error_evolution: List[float] = []

        self.train_handle: Optional[Generator] = None

    @property
    def train_error_evo(self) -> np.array:
        return np.array(self.train_error_evolution)

    @property
    def test_error_evo(self) -> np.array:
        return np.array(self.test_error_evolution)

    def forward_pass(self, x: np.ndarray) -> np.ndarray:
        """Forward pass through the net."""
        self.hidden_output.append(self.layers[0].forward(x))
        self.output.append(self.layers[1].forward(self.hidden_output[-1]))

        return self.output[-1]

    def backward_pass(self, target: np.ndarray) -> None:
        """Gradient descent of backpropagation algorithm.

        The method updates weights of the model.
        Partially inspired by: https://machinelearninggeek.com/backpropagation-neural-network-using-python/
        """
        # calculate weight deltas
        _error_output = target - self.output[-1]
        delta_output = _error_output * self.layers[1].backward(self.output[-1])

        _error_hidden = delta_output.dot(self.layers[1].weights.T)
        delta_hidden = _error_hidden * self.layers[0].backward(self.hidden_output[-1])

        # update weights
        self.layers[1].weights += self.learning_rate * np.dot(self.hidden_output[-1].T, delta_output) / target.shape[0]
        self.layers[0].weights += self.learning_rate * np.dot(target.T, delta_hidden) / target.shape[0]

        # prepare for next epoch
        self.hidden_output, self.output = [], []

    def train(
        self, train_data: np.ndarray, test_data: Optional[np.ndarray] = None, epochs: Optional[int] = 20
    ) -> None:
        """Initialize training of the model.

        Minibatch gradient descent is used in backpropagation algorithm.
        The method returns None, but initializes training handler which can be iterated
        to train the model.
        """
        self.train_handle = self._train(train_data, test_data, epochs)

    def _train(
        self, train_data: np.ndarray, test_data: Optional[np.ndarray] = None, epochs: Optional[int] = 20
    ) -> Optional[Generator]:
        """Implementation of backpropagation algorithm - training of the net."""
        for epoch in range(epochs):
            yield  # allows training step by step
            np.random.shuffle(train_data)

            if test_data is not None:
                # validate model
                self.forward_pass(test_data)
                self.error.append(self.loss(self.output[-1], test_data))
                self.test_error_evolution.append(self.error[-1])

            # calculate error function of training data
            error_func_sample = train_data[np.random.choice(train_data.shape[0], 5000, replace=False)]
            self.error.append(self.loss(self.forward_pass(error_func_sample), error_func_sample))
            self.train_error_evolution.append(self.error[-1])

            # train model
            for batch_i in range(0, train_data.shape[0], self.BATCH_SIZE):
                # mini-batch gradient descent
                self.forward_pass(train_data[batch_i: batch_i + self.BATCH_SIZE])
                self.backward_pass(train_data[batch_i: batch_i + self.BATCH_SIZE])

            print(f"Epoch: {epoch + 1} | Error: {self.error}")
            self.error = []

        self.train_handle = None

    def next_epoch(self):
        """Train the model for one epoch - 'one step'."""
        try:
            self.train_handle.__iter__().__next__()
        except Exception:
            ...

    def all_epochs(self):
        """Train the model for all epochs - 'full'."""
        if self.train_handle:
            for _ in self.train_handle:
                pass

    @staticmethod
    def loss(output: np.ndarray, target: np.ndarray) -> float:
        """Loss/Cost/Error function."""
        return np.mean((target - output) ** 2)
