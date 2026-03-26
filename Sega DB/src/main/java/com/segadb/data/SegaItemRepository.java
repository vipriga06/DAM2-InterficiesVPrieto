package com.segadb.data;

import java.util.List;

import com.segadb.SegaItemData;

public interface SegaItemRepository {
    List<SegaItemData> loadItems();
}
