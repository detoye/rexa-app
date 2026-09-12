import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../data/repositories/property_repository.dart';

class PropertyScreen extends StatefulWidget {
  const PropertyScreen({super.key});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  final _propertyRepo = PropertyRepository();
  List<Property> _properties = [];
  List<PropertyDeal> _deals = [];
  bool _isLoading = true;
  String? _estateId;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      _estateId = await _propertyRepo.getCurrentEstateId();
      if (_estateId != null) {
        final results = await Future.wait([
          _propertyRepo.getProperties(_estateId!),
          _propertyRepo.getPropertyDeals(_estateId!),
        ]);
        setState(() {
          _properties = results[0] as List<Property>;
          _deals = results[1] as List<PropertyDeal>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load properties: $e')),
        );
      }
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) return '₦${(price / 1000000000).toStringAsFixed(1)}B';
    if (price >= 1000000) return '₦${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '₦${(price / 1000).toStringAsFixed(0)}K';
    return '₦${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Property'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            onPressed: () => _showAddPropertySheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadProperties,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Listings', style: Theme.of(context).headlineMedium),
                        TextButton(onPressed: () => _showAddPropertySheet(context), child: const Text('+ New Listing')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_properties.isEmpty)
                      _buildEmptyState('No property listings yet')
                    else
                      ..._properties.map((p) => _buildPropertyCard(p)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quick Deals', style: Theme.of(context).headlineMedium),
                        TextButton(onPressed: () => _showAddDealSheet(context), child: const Text('+ Add Deal')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_deals.isEmpty)
                      _buildEmptyState('No deals posted yet')
                    else
                      ..._deals.map((d) => _buildDealCard(d)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: RezaColors.textGray)),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final specs = <String>[];
    if (property.bedrooms != null) specs.add('${property.bedrooms} Bed');
    if (property.bathrooms != null) specs.add('${property.bathrooms} Bath');
    final specsStr = specs.isNotEmpty ? specs.join(' • ') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: RezaColors.borderDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.home, color: RezaColors.textGray, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(property.title, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: property.type == 'sale'
                            ? RezaColors.accentGold.withValues(alpha: 0.2)
                            : RezaColors.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        property.type[0].toUpperCase() + property.type.substring(1),
                        style: TextStyle(
                          color: property.type == 'sale' ? RezaColors.accentGold : RezaColors.successGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(property.description, style: Theme.of(context).bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (specsStr.isNotEmpty) Text(specsStr, style: Theme.of(context).bodyMedium?.copyWith(fontSize: 12)),
                    Text(_formatPrice(property.price), style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(PropertyDeal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: RezaColors.borderDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.home, color: RezaColors.textGray),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.title, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                Text(deal.description, style: Theme.of(context).bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatPrice(deal.price), style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: deal.dealType == 'sale'
                      ? RezaColors.accentGold.withValues(alpha: 0.2)
                      : RezaColors.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  deal.dealType[0].toUpperCase() + deal.dealType.substring(1),
                  style: TextStyle(
                    color: deal.dealType == 'sale' ? RezaColors.accentGold : RezaColors.successGreen,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPropertySheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final bedsController = TextEditingController();
    final bathsController = TextEditingController();
    String selectedType = 'sale';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Property Listing', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title', prefixIcon: Icon(Icons.title))),
                    const SizedBox(height: 12),
                    TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.description))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(hintText: 'Type'),
                            items: const [
                              DropdownMenuItem(value: 'sale', child: Text('Sale')),
                              DropdownMenuItem(value: 'rent', child: Text('Rent')),
                            ],
                            onChanged: (v) => setModalState(() => selectedType = v ?? 'sale'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price (₦)'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: bedsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Bedrooms'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: bathsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Bathrooms'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_estateId != null && titleController.text.isNotEmpty && priceController.text.isNotEmpty) {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await _propertyRepo.createProperty(
                                estateId: _estateId!,
                                title: titleController.text,
                                description: descController.text,
                                type: selectedType,
                                price: double.parse(priceController.text),
                                bedrooms: bedsController.text.isNotEmpty ? int.parse(bedsController.text) : null,
                                bathrooms: bathsController.text.isNotEmpty ? int.parse(bathsController.text) : null,
                              );
                              navigator.pop();
                              _loadProperties();
                              messenger.showSnackBar(const SnackBar(content: Text('Property listed')));
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          }
                        },
                        child: const Text('List Property'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDealSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String selectedType = 'sale';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Quick Deal', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title', prefixIcon: Icon(Icons.title))),
                  const SizedBox(height: 12),
                  TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.description))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(hintText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'sale', child: Text('Sale')),
                            DropdownMenuItem(value: 'rent', child: Text('Rent')),
                          ],
                          onChanged: (v) => setModalState(() => selectedType = v ?? 'sale'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price (₦)'))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_estateId != null && titleController.text.isNotEmpty && priceController.text.isNotEmpty) {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _propertyRepo.createDeal(
                              estateId: _estateId!,
                              title: titleController.text,
                              description: descController.text,
                              dealType: selectedType,
                              price: double.parse(priceController.text),
                            );
                            navigator.pop();
                            _loadProperties();
                            messenger.showSnackBar(const SnackBar(content: Text('Deal posted')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        }
                      },
                      child: const Text('Post Deal'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
