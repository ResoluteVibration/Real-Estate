import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../providers/city_provider.dart';
import '../models/city.dart';
import '../theme/custom_colors.dart';

class CityDropdown extends StatefulWidget {
  final String? selectedCity;
  final Function(String?) onCitySelected;

  const CityDropdown({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  State<CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  Future<void> _handleCitySelection(BuildContext context, String? value) async {
    if (value == 'No City Selected') {
      final newCityName = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final newCityController = TextEditingController();
          return AlertDialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            title: Text(
              'List Your City',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
            ),
            content: TextField(
              controller: newCityController,
              decoration: InputDecoration(
                hintText: "Enter new city name",
                hintStyle: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Cancel',
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.primary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(newCityController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                ),
                child: const Text('Add City'),
              ),
            ],
          );
        },
      );

      if (newCityName != null && newCityName.isNotEmpty) {
        final cityProvider = Provider.of<CityProvider>(context, listen: false);
        final newCity = await cityProvider.addCity(newCityName);
        if (newCity != null) {
          widget.onCitySelected(newCity.cityId);
        }
      }
    } else {
      widget.onCitySelected(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CityProvider>(
      builder: (context, cityProvider, child) {
        if (cityProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final cities = cityProvider.cities;
        return DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSearchBox: cities.length > 5,
            constraints: const BoxConstraints(
              maxHeight: 150, // Height limit
            ),
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: TextStyle(
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ),
              style: TextStyle(color: CustomColors.textPrimary),
            ),
          ),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: 'Select City...',
              hintStyle: TextStyle(color: CustomColors.mutedBlue.withOpacity(0.7)),
              labelStyle: const TextStyle(color: CustomColors.mutedBlue),
            ),
          ),
          items: [
            'No City Selected',
            ...cities.map((city) => city.cityId).toList(),
          ],
          itemAsString: (item) {
            if (item == 'No City Selected') {
              return 'List Your City';
            }
            // Safely find the city in the list to prevent the crash
            City? foundCity;
            for (var city in cities) {
              if (city.cityId == item) {
                foundCity = city;
                break;
              }
            }
            return foundCity?.cityName ?? item; // Return city name if found, otherwise return the item ID
          },
          selectedItem: widget.selectedCity,
          onChanged: (value) async {
            if (value != null) {
              await _handleCitySelection(context, value);
            }
          },
          validator: (value) =>
          value == null ? 'Please select a city' : null,
          clearButtonProps: const ClearButtonProps(isVisible: true),
          dropdownBuilder: (context, selectedItem) {
            if (selectedItem == null) {
              return Text(
                'Select City...',
                style: TextStyle(color: CustomColors.mutedBlue.withOpacity(0.7)),
              );
            }
            // Safely find the city for the dropdown display
            City? foundCity;
            for (var city in cities) {
              if (city.cityId == selectedItem) {
                foundCity = city;
                break;
              }
            }
            return Text(
              foundCity?.cityName ?? selectedItem,
              style: textTheme.bodyLarge!.copyWith(color: CustomColors.mutedBlue),
            );
          },
        );
      },
    );
  }
}
