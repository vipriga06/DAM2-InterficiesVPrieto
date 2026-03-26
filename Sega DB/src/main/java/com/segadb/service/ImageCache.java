package com.segadb.service;

import java.io.InputStream;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

import javafx.scene.image.Image;

public class ImageCache {

    private final Map<String, Image> cache = new ConcurrentHashMap<>();

    public Optional<Image> getImage(Class<?> contextClass, String resourcePath) {
        if (resourcePath == null || resourcePath.isBlank()) {
            return Optional.empty();
        }

        Image cachedImage = cache.get(resourcePath);
        if (cachedImage != null) {
            return Optional.of(cachedImage);
        }

        try (InputStream is = contextClass.getResourceAsStream(resourcePath)) {
            if (is == null) {
                System.err.println("No s'ha trobat la imatge: " + resourcePath);
                return Optional.empty();
            }

            Image loadedImage = new Image(is);
            cache.put(resourcePath, loadedImage);
            return Optional.of(loadedImage);
        } catch (Exception e) {
            System.err.println("Error carregant la imatge: " + resourcePath + " (" + e.getMessage() + ")");
            return Optional.empty();
        }
    }
}
