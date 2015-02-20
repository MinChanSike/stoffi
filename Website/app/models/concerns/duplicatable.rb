# The model of the song resource.
#
# This code is part of the Stoffi Music Player Project.
# Visit our website at: stoffiplayer.com
#
# Author::		Christoffer Brodd-Reijer (christoffer@stoffiplayer.com)
# Copyright::	Copyright (c) 2013 Simplare
# License::		GNU General Public License (stoffiplayer.com/license)
#

# Use this concern to allow a model to have duplicates.
#
# = Examples
#
# Mark a as a duplicate of b:
#   a.duplicate_of b
#
# Get the original, given a duplicate:
#   b.archetype # returns b
#
# By default, relations will filter out any duplicates:
#
#   artist.songs.count # returns 5
#   artist.songs.first.duplicate_of artist.songs.last
#   artist.songs.count # returns 4
#
# You have unscope the relation to include duplicates:
#
#   artist.songs.unscoped.count # returns 5
#
# Duplicates are recursive:
#
#   a.duplicate_of b
#   b.duplicate_of c
#   a.archetype # returns c
#
# Combine associations:
#
#   class Person
#     has_many :hobbies
#     combine_associations :hobbies
#   end
#
# Now `alice.hobbies` will include `bob.hobbies` if you set `bob.duplicate_of alice`.
#
# = Setup
#
# You need to add a migration to your model in order to use
# this concern:
#   rails g migration AddArchetypeToMODEL archetype:references{polymorphic}
#   rake db:migrate
#
module Duplicatable
	extend ActiveSupport::Concern
	
	included do
		has_many :duplicates, as: :archetype, class_name: self.name
		belongs_to :archetype, polymorphic: true
	end
	
	# Mark as a duplicate of another resource
	def duplicate_of(resource)
		self.archetype = resource
	end
	
	def duplicate_of?(resource)
		self.archetype == resource
	end
	
	# Get the archetype (original) of a duplicate
	# Returns itself if it's not marked as a duplicate
	def archetype
		super ? super.archetype : self
	end
	
	# Check if the record is marked as a duplicate
	def duplicate?
		archetype != self
	end
	
	# Returns only duplicates directly under this resource
	def direct_duplicates
		self.class.unscope.where(archetype: self)
	end
	
	# Returns all duplicates of this resource
	def duplicates
		w = ''
		ids = [id]
		children = self.class.unscoped.where(archetype: self)
		i = 0
		while i < children.size
			child = children[i]
			ids << child.id
			children += self.class.unscoped.where(archetype: child)
			i+=1
		end
		ids.map! { |x| "archetype_id=#{x}" }
		ids = ids.join ' or '
		ids = " and (#{ids})" if ids.present?
		w = "archetype_type = '#{self.class.name}' #{ids}"
		self.class.unscoped.where(w)
	end
	
	module ClassMethods
		
		# Filter out duplicates by default
		def default_scope
			where(archetype: nil)
		end
		
		# Turn on merging of associations.
		#
		# When you access the association on an archetype,
		# it will include the associations on all its duplicates
		# as well.
		def combine_associations(*associations)
			associations.each do |association|
				define_method "#{association}" do |*argumets|
					unless self.class.reflections.key? association
						raise "No such association: #{association}"
					end
					reflection = self.class.reflections[association]
					w = ''
					w = "#{reflection.type}=#{self.class.name} and " if reflection.type
					children = ["#{reflection.foreign_key}=#{id}"]
					for duplicate in duplicates
						children << "#{reflection.foreign_key}=#{duplicate.id}"
					end
					w += "(#{children.join(' or ')})"
					reflection.class_name.constantize.where(w)
				end
			end
		end
		
	end
	
end