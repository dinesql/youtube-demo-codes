-- checking whether database has a master key, if not create one
SELECT name
FROM sys.symmetric_keys
WHERE name = '##MS_DatabaseMasterKey##';
GO

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = '<Enter your password>';
GO

-- Add credential for Azure OpenAI service
-- Name of the credential is the endpoint of the Azure OpenAI service
-- If need, you can use name it preferred name.
ALTER DATABASE SCOPED CREDENTIAL [https://dinesql-demo-resource.services.ai.azure.com/]
WITH
    IDENTITY = 'HTTPEndpointHeaders',
    SECRET = '{"api-key":"<Copy the secret from your model and paste>"}';
GO

-- Create external model for Azure OpenAI embeddings
CREATE EXTERNAL MODEL ProductEmbeddingModel
WITH
(
    LOCATION = '<Full path to your model>',
    -- Example: LOCATION = 'https://dinesql-demo-resource.services.ai.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2024-02-01'
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'text-embedding-3-small',
    CREDENTIAL = [https://dinesql-demo-resource.services.ai.azure.com/],
    PARAMETERS = '{"dimensions":1536}'
);
GO

-- Test the external model by generating an embedding for a sample text
DECLARE @TestEmbedding vector(1536);

SET @TestEmbedding =
    AI_GENERATE_EMBEDDINGS(
        N'Comfortable headphones for a long flight'
        USE MODEL ProductEmbeddingModel
    );

SELECT @TestEmbedding,
    VECTORPROPERTY(@TestEmbedding, 'Dimensions') AS Dimensions;

GO


-- Table script
CREATE TABLE dbo.Product
(
    ProductID     int IDENTITY(1,1) PRIMARY KEY,
    ProductName   nvarchar(150) NOT NULL,
    Category      nvarchar(80) NOT NULL,
    Description   nvarchar(1000) NOT NULL,
    Price         decimal(10,2) NOT NULL,
    Embedding     vector(1536) NULL
);
GO

-- Insert sample data into the Product table
INSERT INTO dbo.Product (ProductName, Category, Description, Price)
VALUES
(N'Magnetic Building Tiles', N'Toys',
 N'Colourful magnetic pieces that children ages 5 to 8 can connect to create houses, towers and imaginative structures at home.', 49.00),

(N'Interlocking Building Blocks', N'Toys',
 N'Reusable plastic pieces for children ages 5 and up to construct vehicles, buildings and original designs during independent play.', 39.00),

(N'Junior Marble Run', N'Toys',
 N'Connectable tracks and ramps that children ages 6 and up can arrange into different courses, then watch marbles travel through them.', 45.00),

(N'Dinosaur Jigsaw Puzzle', N'Toys',
 N'A 100-piece puzzle with a dinosaur scene, designed for children ages 6 and up to assemble on a table at home.', 19.00),

(N'Space Explorer Jigsaw Puzzle', N'Toys',
 N'A 120-piece illustrated puzzle featuring planets and spacecraft, suitable for children ages 6 and up.', 21.00),

(N'Children’s Art Kit', N'Toys',
 N'A box of washable markers, coloured pencils, paper and stickers for children to draw and make their own pictures.', 32.00),

(N'Make-Your-Own Clay Set', N'Toys',
 N'Soft modelling clay in multiple colours with simple shaping tools for children to create animals and other figures.', 27.00),

(N'Paper Craft Activity Box', N'Toys',
 N'Pre-cut paper shapes, glue and decorations for children ages 5 to 8 to assemble creative projects at a table.', 24.00),

(N'Memory Matching Card Game', N'Toys',
 N'Illustrated pairs of cards that children can turn over and match, either alone or with family members.', 16.00),

(N'Junior Board Game', N'Toys',
 N'A simple turn-taking game for two to four players ages 6 and up, with colourful pieces and easy-to-follow rules.', 29.00),

(N'Beginner Science Experiment Kit', N'Toys',
 N'Hands-on activities for children ages 6 and up to explore colours, magnets and simple physical reactions with adult supervision.', 42.00),

(N'Kids Coding Robot', N'Toys',
 N'A small programmable robot that children ages 6 and up can guide through simple movement challenges using physical buttons.', 69.00),

(N'Wooden Train Track Set', N'Toys',
 N'Connectable wooden tracks, a train and small scenery pieces for children to design routes and act out journeys.', 54.00),

(N'Pretend Grocery Store Set', N'Toys',
 N'Play food, baskets and a toy checkout for children to act out shopping and practise imaginative role play.', 44.00),

(N'Puppet Theatre Set', N'Toys',
 N'Hand puppets and a small foldable stage that children can use to invent characters and tell stories at home.', 38.00),

(N'Outdoor Flying Disc', N'Toys',
 N'Lightweight flying disc for throwing and catching in a park, garden or other open outdoor space.', 15.00),

(N'Beach Sand Castle Set', N'Toys',
 N'Bucket, spade and moulds for building shapes with sand during beach trips or outdoor play.', 18.00),

(N'Water Blaster', N'Toys',
 N'Handheld water toy for active outdoor games in a garden or open play area.', 22.00),

(N'Children’s Football', N'Toys',
 N'Soft, lightweight ball sized for children to practise kicking and passing in an outdoor play area.', 25.00),

(N'Beginner Kite', N'Toys',
 N'Easy-to-assemble kite with a hand reel for children to fly with an adult in a spacious outdoor area.', 26.00);
 GO


 -- Create a stored procedure to generate embeddings for products
 CREATE OR ALTER PROCEDURE dbo.GenerateProductEmbeddings
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET Embedding = AI_GENERATE_EMBEDDINGS(
        CONCAT(
            p.ProductName,
            N'. Category: ', p.Category,
            N'. ', p.Description
        )
        USE MODEL ProductEmbeddingModel
    )
    FROM dbo.Product AS p
    WHERE p.Embedding IS NULL;

    SELECT @@ROWCOUNT AS ProductsUpdated;
END;
GO


-- Create a stored procedure to search products based on a search text
CREATE OR ALTER PROCEDURE dbo.SearchProducts
    @SearchText nvarchar(1000),
    @Top int = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SearchEmbedding vector(1536);

    SET @SearchEmbedding =
        AI_GENERATE_EMBEDDINGS(
            @SearchText USE MODEL ProductEmbeddingModel
        );

    SELECT TOP (@Top)
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Description,
        p.Price,
        VECTOR_DISTANCE(
            'cosine', p.Embedding, @SearchEmbedding
        ) AS CosineDistance
    FROM dbo.Product AS p
    WHERE p.Embedding IS NOT NULL
    ORDER BY CosineDistance ASC;
END;
GO


-- Test the stored procedures
EXEC dbo.SearchProducts 'I need something to keep my six-year-old busy indoors on a rainy day.', 30







