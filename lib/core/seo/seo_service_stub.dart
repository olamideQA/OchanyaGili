import 'package:ochanya_gili/core/seo/seo_metadata.dart';

SeoMetadata? lastAppliedMetadata;

void applySeoMetadataWeb(SeoMetadata metadata) {
  // In VM/test environments, record the applied metadata for test assertions
  lastAppliedMetadata = metadata;
}
