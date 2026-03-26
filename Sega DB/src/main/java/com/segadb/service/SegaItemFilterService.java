package com.segadb.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import com.segadb.SegaItemData;

public class SegaItemFilterService {

    private static final Comparator<SegaItemData> NAME_COMPARATOR =
        Comparator.comparing(SegaItemData::getName, String.CASE_INSENSITIVE_ORDER);

    private final Map<String, List<SegaItemData>> itemsByType = new LinkedHashMap<>();
    private final Map<String, List<String>> categoriesByType = new LinkedHashMap<>();
    private final Set<String> availableTypes = new LinkedHashSet<>();

    public void index(List<SegaItemData> items) {
        itemsByType.clear();
        categoriesByType.clear();
        availableTypes.clear();

        for (SegaItemData item : items) {
            String type = item.getType();
            availableTypes.add(type);
            itemsByType.computeIfAbsent(type, key -> new ArrayList<>()).add(item);
        }

        for (Map.Entry<String, List<SegaItemData>> entry : itemsByType.entrySet()) {
            List<SegaItemData> typedItems = entry.getValue();
            typedItems.sort(NAME_COMPARATOR);

            List<String> categories = typedItems.stream()
                .map(SegaItemData::getGame)
                .distinct()
                .sorted(String.CASE_INSENSITIVE_ORDER)
                .collect(Collectors.toCollection(ArrayList::new));

            categoriesByType.put(entry.getKey(), Collections.unmodifiableList(categories));
            entry.setValue(Collections.unmodifiableList(typedItems));
        }
    }

    public List<String> getAvailableTypes() {
        return new ArrayList<>(availableTypes);
    }

    public List<String> getCategoriesForType(String type) {
        return categoriesByType.getOrDefault(type, Collections.emptyList());
    }

    public List<SegaItemData> filter(String type, String category) {
        List<SegaItemData> itemsOfType = itemsByType.getOrDefault(type, Collections.emptyList());
        if (category == null || category.isBlank() || "Tots".equals(category)) {
            return itemsOfType;
        }

        List<SegaItemData> filtered = new ArrayList<>();
        for (SegaItemData item : itemsOfType) {
            if (category.equals(item.getGame())) {
                filtered.add(item);
            }
        }
        return filtered;
    }
}
