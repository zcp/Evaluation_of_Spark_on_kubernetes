# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""
A simple example demonstrating basic Spark SQL features.
Run with:
  ./bin/spark-submit examples/src/main/python/sql/basic.py
"""
from __future__ import print_function

# $example on:init_session$
from pyspark.sql import SQLContext
from pyspark.sql import SparkSession
# $example off:init_session$

# $example on:schema_inferring$
from pyspark.sql import Row
# $example off:schema_inferring$

# $example on:programmatic_schema$
# Import data types
from pyspark.sql.types import *
# $example off:programmatic_schema$
import sys
from datetime import datetime
import time

def df_join(spark, users_data, urls_data):
    # $example on:schema_inferring$
    sc = spark.sparkContext

    # Load a text file and convert each line to a Row.
    lines = sc.textFile(users_data)
    parts = lines.map(lambda l: l.split(","))
    users = parts.map(lambda p: Row(name=p[0], url=p[1]))

    # Infer the schema, and register the DataFrame as a table.
    schemaUsers = spark.createDataFrame(users)
    schemaUsers.createOrReplaceTempView("users")


    lines = sc.textFile(urls_data)
    parts = lines.map(lambda l: l.split(","))
    urls = parts.map(lambda p: Row(url=p[0], count=int(p[1])))

    # Infer the schema, and register the DataFrame as a table.
    schemaUrls = spark.createDataFrame(urls)
    schemaUrls.createOrReplaceTempView("urls")
    

    # SQL can be run over DataFrames that have been registered as a table.
    spark.sql("SELECT COUNT(*) FROM users u1 JOIN urls u2 on u1.url = u2.url").show()



if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: SQL join <file> <input data 1> <input data 2> <save_execution_time>", file=sys.stderr)
        exit(-1)

    print("""WARN: This is a naive implementation of PageRank and is
          given as an example! Please refer to PageRank implementation provided by graphx""",
          file=sys.stderr)

    # $example on:init_session$
    spark = SparkSession \
        .builder \
        .appName("Python Spark SQL basic example") \
        .config("spark.some.config.option", "some-value") \
        .getOrCreate()
    # $example off:init_session$
    users_data = sys.argv[1]
    urls_data = sys.argv[2]

    f_exe_time = open(sys.argv[3], "w")
    start_time = str(datetime.now())
    start_millis = int(round(time.time() * 1000))

    df_join(spark, users_data, urls_data)

    end_millis = int(round(time.time() * 1000))
    end_time = str(datetime.now())
    f_exe_time.write("execution time(ms),%s,start time,%s,end time,%s\n" %(str(end_millis - start_millis),start_time,end_time))
    f_exe_time.close()

    spark.stop()

