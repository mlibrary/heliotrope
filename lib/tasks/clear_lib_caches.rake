# frozen_string_literal: true

desc "clear all lib caches"
namespace :heliotrope do
  task clear_all_caches: :environment do
    FactoryService.clear_caches
  end
end

desc "clear epub cache"
namespace :heliotrope do
  task clear_epub_cache: :environment do
    FactoryService.clear_e_pub_publication_cache
  end
end

desc "purge epub from cache"
namespace :heliotrope do
  task purge_epub_from_cache: :environment do
    noid = prompt_for_noid
    FactoryService.e_pub_publication(noid)
  end
end

desc "clear webgl cache"
namespace :heliotrope do
  task clear_webgl_cache: :environment do
    FactoryService.clear_webgl_unity_cache
  end
end

desc "purge webgl from cache"
namespace :heliotrope do
  task purge_webgl_from_cache: :environment do
    noid = prompt_for_noid
    FactoryService.purge_webgl_unity(noid)
  end
end

def prompt_for_noid
  print 'NOID: '
  $stdin.gets.chomp
end
