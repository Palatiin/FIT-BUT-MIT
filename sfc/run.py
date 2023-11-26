# File: run.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Main script

from dataclasses import dataclass

import numpy as np
import matplotlib.pyplot as plt

from src.functions import ActivationFunction, Linear, ReLU, Sigmoid
from src.layers import Layer
from src.model import AutoencoderModel


@dataclass
class Config:
    # autoencoder net config
    hidden_layer_size: int = 64
    hidden_layer_activation: ActivationFunction = ReLU()
    output_layer_activation: ActivationFunction = Sigmoid()

    # training config
    epochs: int = 20
    learning_rate: float = 0.1


def min_max_normalization(arr: np.array, max_val: float) -> np.ndarray:
    # min_val = np.min(arr)
    normalized_arr = arr / max_val
    return normalized_arr


def plot(train_error: np.array, test_error: np.array, conf: Config):
    # max_val = np.max(train_error) if test_error.size is None else np.max([np.max(train_error), np.max(test_error)])
    plt.plot(range(conf.epochs), train_error, label="Training data error")
    if test_error.size:
        plt.plot(range(conf.epochs), test_error, label="Test data error")

    plt.xlabel("Epoch")
    plt.title(f"Error evolution over epochs. hidden={conf.hidden_layer_size}, l_rate={conf.learning_rate}")
    plt.legend()
    plt.show()


if __name__ == "__main__":
    config = Config(**{
        "hidden_layer_size": 400,
        "hidden_layer_activation": ReLU(),
        "output_layer_activation": Sigmoid(),
        "epochs": 10,
        "learning_rate": 0.8,
    })

    # load data
    train_data = np.loadtxt("data/mnist-tr.inp")
    test_data = np.loadtxt("data/mnist-tk.inp")

    # normalize data and remove label (last column says which digit is on the image)
    train_data = train_data[:, :-1] / 255.0
    test_data = test_data[:, :-1] / 255.0

    # initialize model
    model = AutoencoderModel(
        layers=[
            Layer(
                base=Linear(input_dim=train_data.shape[1], output_dim=config.hidden_layer_size),
                activation=config.hidden_layer_activation
            ),
            Layer(
                base=Linear(input_dim=config.hidden_layer_size, output_dim=train_data.shape[1]),
                activation=config.output_layer_activation
            )
        ],
        lr=config.learning_rate,
    )

    # train model
    model.train(train_data, test_data, epochs=config.epochs)
    model.all_epochs()

    # plot results
    plot(model.train_error_evo, model.test_error_evo, conf=config)
