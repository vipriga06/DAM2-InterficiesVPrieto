package com.segadb;

import java.util.Objects;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerItem1 {

    @FXML
    private Label title;      // Para el nombre del personaje

    @FXML
    private Label subtitle;   // Para el nombre del juego

    @FXML
    private ImageView image;  // Imagen del personaje

    @FXML
    private Circle circle;    // Círculo para mostrar el color

    // Setea el título (nombre)
    public void setTitle(String title) {
        this.title.setText(title);
    }

    // Setea el subtítulo (nombre del juego)
    public void setSubtitle(String subtitle) {
        this.subtitle.setText(subtitle);
    }

    // Carga la imagen desde ruta relativa (debe ser ruta completa en classpath)
    public void setImage(String imagePath) {
        try {
            Image img = new Image(Objects.requireNonNull(getClass().getResourceAsStream(imagePath)));
            this.image.setImage(img);
        } catch (NullPointerException e) {
            System.err.println("Error loading image asset: " + imagePath);
            e.printStackTrace();
        }
    }

    // Cambia el color de relleno del círculo
    public void setCircleColor(String color) {
        circle.setStyle("-fx-fill: " + color);
    }

    // Método para manejar el clic en el ítem (opcional, si quieres manejar aquí el evento)
    @FXML
    private void onItemClicked(MouseEvent event) {
        // Aquí podrías notificar al controlador principal o hacer algo
        // Por ejemplo, si usas UtilsViews para cambiar vista:
        // ControllerCharacter crtl = (ControllerCharacter) UtilsViews.getController("ViewCharacter");
        // crtl.setNom(title.getText());
        // crtl.setCircle(circle.getStyle());
        // crtl.setGame(subtitle.getText());
        // crtl.setImage(image.getImage());
        // UtilsViews.setViewAnimating("ViewCharacter");
    }
}
