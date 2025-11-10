Spatial Bill of Lading (SBOL) for Apple Vision Pro

This application renders 3-dimensional views of shipment containers based on the Quick Pallet Maker API. Using information from compatible JSONs, SBOL shows the user a RealityView of the containers and their contents, along with relevant information such as the box count and container fill efficiency. 

The application has three main options:

1. Fetch JSON from API: using the Quick Pallet Maker API, the user is able to obtain a Spatial Bill of Lading (SBOL) JSON from the database for a given shipment of containers. If the shipment ID is found, the application will show the containers' information and a 3D visualization for each container.

2. Show recent containers: the application will save the shipments obtained from the API in a buffer so they can be inspected later using this option. Ideal for offline scenarios.

3. Fetch JSON from file: if the user has local JSON files obtained from the Quick Pallet Maker software, the application will read the file and show the information and 3D render based on the JSON.
