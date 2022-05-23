from handling.gdelt import process, growthRate, handleHelperTables

if __name__ == '__main__':
    handleHelperTables(1)
    process(1)
    growthRate(1)

    handleHelperTables(2, ['GOV'])
    processSubset(2, ['GOV'])
    growthRate(2)
    
    handleHelperTables(3, [], 2)
    processSubset(3, [])
    growthRate(3)