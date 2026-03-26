package com.segadb.data;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Scanner;

import org.json.JSONArray;
import org.json.JSONObject;

import com.segadb.SegaItemData;

public class JsonSegaItemRepository implements SegaItemRepository {

    private final String resourcePath;

    public JsonSegaItemRepository(String resourcePath) {
        this.resourcePath = resourcePath;
    }

    @Override
    public List<SegaItemData> loadItems() {
        try (InputStream is = getClass().getResourceAsStream(resourcePath)) {
            if (is == null) {
                System.err.println("No s'ha trobat el fitxer JSON: " + resourcePath);
                return Collections.emptyList();
            }

            String jsonText;
            try (Scanner scanner = new Scanner(is, StandardCharsets.UTF_8)) {
                jsonText = scanner.useDelimiter("\\A").next();
            }

            JSONArray array = new JSONArray(jsonText);
            List<SegaItemData> loadedItems = new ArrayList<>(array.length());
            for (int i = 0; i < array.length(); i++) {
                JSONObject obj = array.getJSONObject(i);
                loadedItems.add(
                    new SegaItemData(
                        obj.getString("name"),
                        obj.getString("image"),
                        obj.getString("color"),
                        obj.getString("game"),
                        obj.getString("type")
                    )
                );
            }
            return loadedItems;
        } catch (Exception e) {
            System.err.println("Error carregant l'arxiu JSON: " + resourcePath + " (" + e.getMessage() + ")");
            return Collections.emptyList();
        }
    }
}
