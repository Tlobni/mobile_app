import 'package:flutter/material.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

// Provider card widget to display provider search results
class ProviderSearchScreenCard extends StatelessWidget {
  final UserModel provider;

  const ProviderSearchScreenCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.color.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: provider.profile != null && provider.profile!.isNotEmpty
                ? UiUtils.getImage(
                    provider.profile!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 60,
                    width: 60,
                    color: context.color.territoryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: context.color.territoryColor,
                      size: 30,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Provider details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and type
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        provider.name ?? "Unknown",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.color.textColorDark,
                      ),
                    ),
                    if (provider.isVerified == 1)
                      Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Provider type
                CustomText(
                  provider.categoriesModels?.isEmpty ?? false
                      ? provider.type ?? ''
                      : UiUtils.categoriesListToString(provider.categoriesModels!),
                  fontSize: 14,
                  color: context.color.textDefaultColor.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                // Location
                if (provider.location != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: context.color.territoryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          provider.location.toString(),
                          fontSize: 12,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: context.color.textDefaultColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Arrow icon
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.color.textDefaultColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
