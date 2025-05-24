import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns

import kagglehub

path = kagglehub.dataset_download("lexset/synthetic-asl-alphabet")

print("Path to dataset files:", path)

!ls /root/.cache/kagglehub/datasets/lexset/synthetic-asl-alphabet/versions/3

!cp -r /root/.cache/kagglehub/datasets/lexset/synthetic-asl-alphabet/versions/3/* ./

TARGET_LETTERS = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K']

BASE_DIR = '/content/Dataset'
TRAIN_DIR = '/content/Train_Alphabet'
TEST_DIR = '/content/Test_Alphabet'

print("Training folders:", os.listdir(TRAIN_DIR) if os.path.exists(TRAIN_DIR) else "Not found")
print("Testing folders:", os.listdir(TEST_DIR) if os.path.exists(TEST_DIR) else "Not found")

BATCH_SIZE = 32
IMG_SIZE = 224  # حجم الصورة المطلوب لـ MobileNetV2
EPOCHS = 25

train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode='nearest',
    validation_split=0.2
)

test_datagen = ImageDataGenerator(rescale=1./255)

train_generator = train_datagen.flow_from_directory(
    TRAIN_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    classes=TARGET_LETTERS,
    subset='training'
)

validation_generator = train_datagen.flow_from_directory(
    TRAIN_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    classes=TARGET_LETTERS,
    subset='validation'
)

test_generator = test_datagen.flow_from_directory(
    TEST_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    classes=TARGET_LETTERS,
    shuffle=False
)

print("Number of classes:", len(train_generator.class_indices))
print("Class mapping:", train_generator.class_indices)

base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(IMG_SIZE, IMG_SIZE, 3))

# تجميد طبقات البيز موديل
base_model.trainable = False

# اضافت لير اعلي البيز موديل
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(512, activation='relu')(x)
x = Dropout(0.5)(x)
x = Dense(256, activation='relu')(x)
x = Dropout(0.3)(x)
predictions = Dense(len(TARGET_LETTERS), activation='softmax')(x)

model = Model(inputs=base_model.input, outputs=predictions)

model.compile(
    optimizer=Adam(learning_rate=0.001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

model.summary()

callbacks = [
    ModelCheckpoint('best_sign_language_model.h5', save_best_only=True, monitor='val_accuracy'),
    EarlyStopping(patience=7, monitor='val_loss', restore_best_weights=True),
    ReduceLROnPlateau(factor=0.2, patience=3, min_lr=1e-6)
]

# تدريب الموديل
history = model.fit(
    train_generator,
    steps_per_epoch=train_generator.samples // BATCH_SIZE,
    epochs=EPOCHS,
    validation_data=validation_generator,
    validation_steps=validation_generator.samples // BATCH_SIZE,
    callbacks=callbacks
)

test_loss, test_acc = model.evaluate(test_generator)
print(f"Test accuracy: {test_acc:.4f}")

plt.figure(figsize=(12, 4))

# Accuracy plot
plt.subplot(1, 2, 1)
plt.plot(history.history['accuracy'])
plt.plot(history.history['val_accuracy'])
plt.title('Model Accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Training', 'Validation'], loc='lower right')

# Loss plot
plt.subplot(1, 2, 2)
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model Loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Training', 'Validation'], loc='upper right')

plt.tight_layout()
plt.show()

predictions = model.predict(test_generator)
y_pred = np.argmax(predictions, axis=1)

y_true = test_generator.classes

class_labels = list(train_generator.class_indices.keys())
print("\nClassification Report:")
print(classification_report(y_true, y_pred, target_names=class_labels))

plt.figure(figsize=(10, 8))
cm = confusion_matrix(y_true, y_pred)
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=class_labels, yticklabels=class_labels)
plt.title('Confusion Matrix')
plt.ylabel('True Label')
plt.xlabel('Predicted Label')
plt.show()

print("\nPerforming fine-tuning on the model")
for layer in base_model.layers[-20:]:
    layer.trainable = True

# إعادة تجميع الموديل بمعدل تعلم أقل
model.compile(
    optimizer=Adam(learning_rate=0.0001),  # معدل تعلم أقل للتدريب الدقيق
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# تدريب الموديل مرة أخرى
history_fine = model.fit(
    train_generator,
    steps_per_epoch=train_generator.samples // BATCH_SIZE,
    epochs=10,
    validation_data=validation_generator,
    validation_steps=validation_generator.samples // BATCH_SIZE,
    callbacks=callbacks
)

test_loss, test_acc = model.evaluate(test_generator)
print(f"Test accuracy after fine-tuning: {test_acc:.4f}")

model.save('sign_language_model_final.h5')
print("Final model saved.")

def predict_sign(image_path):
    from tensorflow.keras.preprocessing import image

    img = image.load_img(image_path, target_size=(IMG_SIZE, IMG_SIZE))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = img_array / 255.0

    prediction = model.predict(img_array)
    predicted_class = np.argmax(prediction, axis=1)[0]
    confidence = np.max(prediction) * 100

    return class_labels[predicted_class], confidence

sign, conf = predict_sign('/content/a.jpg')
print(f"Predicted sign: {sign} with confidence: {conf:.2f}%")

import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image

model = load_model('sign_language_model_final.h5')

IMG_SIZE = 224
class_labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K']

def predict_sign_fromsavedmodel(image_path):
    img = image.load_img(image_path, target_size=(IMG_SIZE, IMG_SIZE))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = img_array / 255.0

    prediction = model.predict(img_array)
    predicted_class = np.argmax(prediction, axis=1)[0]
    confidence = np.max(prediction) * 100

    return class_labels[predicted_class], confidence

sign, conf = predict_sign_fromsavedmodel('/content/k1.jpg')
print(f"Predicted sign: {sign} with confidence: {conf:.2f}%")

import tensorflow as tf

def convert_to_tflite(keras_model_path, tflite_model_path):
    model = tf.keras.models.load_model(keras_model_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_model)
    print(f"TFLite model saved to {tflite_model_path}")

convert_to_tflite('sign_language_model_final.h5', 'sign_language_model.tflite')