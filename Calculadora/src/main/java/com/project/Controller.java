package com.project;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;

public class Controller {

    @FXML
    private TextField resultField;

    private StringBuilder expression = new StringBuilder();

    @FXML
    private void handleNumber(ActionEvent event) {
        String buttonText = ((Button) event.getSource()).getText();
        expression.append(buttonText);
        resultField.setText(expression.toString());
    }

    @FXML
    private void handleOperator(ActionEvent event) {
        String buttonText = ((Button) event.getSource()).getText();
        expression.append(" ").append(buttonText).append(" ");
        resultField.setText(expression.toString());
    }

    @FXML
    private void handleEquals(ActionEvent event) {
        try {
            String exp = expression.toString().replaceAll("\\s+", "");
            double result = eval(exp);
            resultField.setText(String.valueOf(result));
            expression.setLength(0);
            expression.append(result);
        } catch (Exception e) {
            resultField.setText("Error");
            expression.setLength(0);
        }
    }

    @FXML
    private void handleClear(ActionEvent event) {
        expression.setLength(0);
        resultField.setText("");
    }

    private double eval(String exp) {
        if (exp.contains("+")) {
            String[] parts = exp.split("\\+");
            return Double.parseDouble(parts[0]) + Double.parseDouble(parts[1]);
        } else if (exp.contains("-")) {
            String[] parts = exp.split("-");
            return Double.parseDouble(parts[0]) - Double.parseDouble(parts[1]);
        } else if (exp.contains("*")) {
            String[] parts = exp.split("\\*");
            return Double.parseDouble(parts[0]) * Double.parseDouble(parts[1]);
        } else if (exp.contains("/")) {
            String[] parts = exp.split("/");
            return Double.parseDouble(parts[0]) / Double.parseDouble(parts[1]);
        }
        return Double.parseDouble(exp);
    }
}
