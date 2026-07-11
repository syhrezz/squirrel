/// Re-export of SellingOption for use by the product repository layer.
///
/// The canonical SellingOption in-memory model lives in the penjualan feature
/// but is also needed by the product repository for type-safe option handling.
/// This file provides a lightweight input model used only during form save.
export '../../../penjualan/models/selling_option.dart';
