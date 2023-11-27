# File: app.py
# Project: Soft Computing - Demonstration of autoencoder deep neural network learning
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Date: 2023-11-24
# Description: Simple web UI for demonstration of autoencoder deep neural network learning

import base64
import io
import os.path
from typing import Optional

from run import Config
from src.functions import Linear, ReLU, Sigmoid
from src.layers import Layer
from src.model import AutoencoderModel

import imageio
import numpy as np
from matplotlib import pyplot as plt

from flask import Flask, render_template, request

app = Flask("Autoencoder NN")
config: Optional[Config] = None
model: Optional[AutoencoderModel] = None


def init_model(form: dict) -> None:
    """Initialize the Autoencoder Neural Network model."""
    global config, model

    config = Config(**{
        "hidden_layer_size": int(form.get("hidden_layer_size", 128)),
        "hidden_layer_activation": Sigmoid() if form.get("hidden_layer_activation") == "Sigmoid" else ReLU(),
        "output_layer_activation": Sigmoid(),
        "epochs": int(form.get("epochs", 10)),
        "learning_rate": float(form.get("learning_rate", 0.2)),
    })

    model = AutoencoderModel(
        layers=[
            Layer(
                base=Linear(input_dim=784, output_dim=config.hidden_layer_size),
                activation=config.hidden_layer_activation,
            ),
            Layer(
                base=Linear(input_dim=config.hidden_layer_size, output_dim=784),
                activation=config.output_layer_activation,
            ),
        ],
        lr=config.learning_rate,
    )


def load_dataset_and_prepare_for_training() -> None:
    global model

    # load data
    train_data = np.loadtxt("data/mnist-tr.inp")
    test_data = np.loadtxt("data/mnist-tk.inp")

    # normalize data and remove label (last column says which digit is on the image)
    train_data = train_data[:, :-1] / 255.0
    test_data = test_data[:, :-1] / 255.0

    # prepare for training the model
    model.train(train_data, test_data, epochs=config.epochs)


def generate_plot():
    """Generate plot of error function evolution over epochs in format suitable for rendering in HTML."""
    global config, model

    if not model.train_error_evo.size:
        return None

    plt.plot(range(model.train_error_evo.size), model.train_error_evo, label="Training data error")
    if model.test_error_evo.size:
        plt.plot(range(model.test_error_evo.size), model.test_error_evo, label="Test data error")
    plt.xlabel("Epochs")
    plt.ylabel("Error value")
    plt.title("Error function evolution over epochs")
    plt.legend()

    # Save the plot to a BytesIO object
    image_stream = io.BytesIO()
    plt.savefig(image_stream, format="png")
    image_stream.seek(0)
    plt.close()

    # convert the BytesIO object to a base64-encoded string
    encoded_image = base64.b64encode(image_stream.read()).decode("utf-8")

    return f"data:image/png;base64,{encoded_image}"


def gif_to_numpy(file_path):
    """Convert GIF image to numpy array."""
    gif_reader = imageio.get_reader(os.path.join("data", "train", "00000-00999", file_path))
    frames = []
    for frame in gif_reader:
        frames.append(frame)

    # Flatten, and normalize the first frame, so it can be used as input for the net
    # Note: training dataset contains GIF images with only one frame
    gif_array = frames[0].flatten() / 255.0

    return gif_array


def plot_image(image: np.ndarray, title: str):
    """Plot GIF image in numpy array format.

    The function is used to format original and recreated images by the net in format
    suitable for rendering in HTML.
    """
    plt.imshow(image, cmap="gray")
    plt.title(title)
    img_bytes = io.BytesIO()
    plt.savefig(img_bytes, format='png')
    img_bytes.seek(0)
    plt.close()

    encoded_image = base64.b64encode(img_bytes.read()).decode('utf-8')

    return f"data:image/png;base64,{encoded_image}"


@app.route("/ping")
def ping():
    """Healthcheck."""
    return "pong"


@app.route("/")
def index():
    """Simple page for configuring the model."""
    return render_template("web.html")


@app.route("/train", methods=["POST"])
def train():
    """Simple page for visualizing training of the model, and option to test the model on custom image.

    The page is rendered from template 'train.html', and requires form data from the previous page '/'
    to configure the model. The custom image should be in GIF format, and should be in the same format
    as the images in the training dataset. MNIST dataset, which contains 28x28 images, is used for training.
    """
    global model

    if not request.form.get("action") or request.form.get("action") not in ("step", "full", "image"):
        init_model(request.form.to_dict())
        load_dataset_and_prepare_for_training()
        return render_template("train.html", form_data=request.form.to_dict())

    image_nn, img_orig = None, None
    if request.form.get("action") == "step":
        model.next_epoch()
    elif request.form.get("action") == "full":
        model.all_epochs()
    elif request.form.get("action") == "image":
        image_in = gif_to_numpy(request.form.get("image"))
        output = model.forward_pass(image_in)
        output *= 255.0
        img_orig = plot_image((image_in * 255.0).reshape(28, 28), title="Original Image")
        image_nn = plot_image(output.reshape(28, 28), title="Recreated Image")

    plot = generate_plot()
    if plot:
        if image_nn:
            return render_template(
                "train.html",
                form_data=request.form.to_dict(),
                plot=plot,
                img_orig=img_orig,
                img_nn=image_nn,
            )
        return render_template("train.html", form_data=request.form.to_dict(), plot=plot)
    return render_template("train.html", form_data=request.form.to_dict())


if __name__ == "__main__":
    app.run()
