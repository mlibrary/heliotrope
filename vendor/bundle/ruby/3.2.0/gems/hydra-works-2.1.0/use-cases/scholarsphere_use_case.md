# Penn State ScholarSphere work use cases

Sponsor: @mjgiarlo

Given a scholarly work with one or more files  
As a user  
I want to manage, preserve, and share the work that contains the files  
And I want to maintain the relationships between works and the files in which they are represented  
And I want files to be characterized with technical metadata  
So that I can more accurately and efficiently represent multi-file works than now (when I must apply granular descriptive metadata at the file level, and group files into collections).  

Given one or more works to which I have access in ScholarSphere  
As a user  
I want to group my works into collections  
And I want to allow other users to be able to do the same, possibly with the same works I have grouped into a collection  
So that I may better highlight aggregations of works, e.g., the work of a particular department, class, or discipline  

The domain model I am getting at (though not entirely covering) above:

 * Work has a unique identifier
 * Work has many (0..n) Files
 * Work has descriptive metadata
 * Work may belong to many (0..n) Collections
 * Work may be related to other Works
 * File has a unique identifier
 * File must belong to one and only one Work
 * File has binary content/payload
 * File has technical metadata
 * File may have descriptive metadata independent of containing Work
 * Collection has a unique identifier
 * Collection has many (0..n) Works
 * Collection has descriptive metadata independent of contained Works
